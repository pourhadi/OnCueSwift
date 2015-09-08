//
//  eProder.wf
//  OnCueX
//
//  Creaed by Dane Pourhad on 6/27/15.
//  Copyrgh © 2015 Dane Pourhad. A rgh reered.
//

import UIKit
import MediaPlayer
import ReactiveCocoa

protocol ItemProviderDelegate:class {
    func itemProvider(provider:ItemProvider, pushVCForVM:ListVM)
}

enum SourceCollectionType:String {
    case Artists = "Artists"
    case Albums = "Albums"
    case Playlists = "Playlists"
}

class ItemProvider:ListVMDelegate {
    weak var delegate:ItemProviderDelegate?
    let providers:[SourceItemProvider] = [SpotifyProvider(), LibraryProvider()]
    
    func getCollections(type:SourceCollectionType) -> SignalProducer<ListVM, NSError> {
        return SignalProducer {
            sink, disposable in
            var signals:[RACSignal] = []
            for provider in self.providers {
                signals.append(toRACSignal(provider.getCollections(type)))
            }
            var lists:[ItemList] = []
            RACSignal.merge(signals).subscribeNext({ (obj) -> Void in
                if let list = obj as? TrackCollectionList {
                    lists.append(list)
                }
                }, completed: { () -> Void in
                    sendNext(sink, ListVM(lists: lists, displayContext: CustomDisplayContext(type.rawValue), delegate: self))
                    sendCompleted(sink)
            })
        }
    }
    
    func listVM(listVM:ListVM, selectedItem:protocol<Item>, deselect:(deselect:Bool)->Void) {
        if let collectionItem = selectedItem as? TrackCollection {
            if let artistItem = collectionItem as? ArtistItem {
                artistItem.getAlbums(0, complete: { (albums) -> Void in
                    if let albums = albums {
                        let list = TrackCollectionList(list: albums)
                        let vm = ListVM(lists: [list], displayContext: artistItem, delegate: self)
                        if let delegate = self.delegate {
                            delegate.itemProvider(self, pushVCForVM:vm)
                        }
                    }
                })
            } else {
                collectionItem.getTracks(0, complete: { (list) -> Void in
                    if let list = list {
                        let tracks = TrackList(list: list)
                        let vm = ListVM(lists: [tracks], displayContext: collectionItem, delegate: self)
                        if let delegate = self.delegate {
                            delegate.itemProvider(self, pushVCForVM:vm)
                        }
                    }
                })
            }
            deselect(deselect: false)
        } else if let trackItem = selectedItem as? TrackItem {
            deselect(deselect: true)
            _trackManager.trackSelected(trackItem)
        }
    }
}

protocol SourceItemProvider {
    func getCollections(type:SourceCollectionType) -> SignalProducer<TrackCollectionList, NSError>
}

class LibraryProvider:SourceItemProvider {
    func getCollections(type:SourceCollectionType) -> SignalProducer<TrackCollectionList, NSError> {
        var query:MPMediaQuery
        switch type {
        case .Artists:
            query = MPMediaQuery.artistsQuery()
        case .Albums:
            query = MPMediaQuery.albumsQuery()
        case .Playlists:
            query = MPMediaQuery.playlistsQuery()
        }
        
        return self.getCollections(query, type: type)
    }

    func getCollections(forQuery:MPMediaQuery, type:SourceCollectionType) -> SignalProducer<TrackCollectionList, NSError> {
        return SignalProducer {
            sink, disposable in
            let sink = sink
            if let collections = forQuery.collections {
                let array:[TrackCollection] = collections.map({ (collection) -> TrackCollection in
                    switch type {
                    case .Artists:
                        return LibraryArtist(collection: collection)
                    case .Albums:
                        return LibraryAlbum(collection: collection)
                    case .Playlists:
                        return LibraryPlaylist(playlist: collection as! MPMediaPlaylist)
                    }
                })
                let list = List(items: array, totalCount: UInt(array.count), pageNumber: 0)
                let colList = TrackCollectionList(list: list)
                sendNext(sink, colList)
                sendCompleted(sink)
            }
        }
    }
}

let kSpotifyErrorDomain = "com.pourhadi.OnCue.Spotify.Error"
class SpotifyProvider:SourceItemProvider {
    
    func getCollections(type:SourceCollectionType) -> SignalProducer<TrackCollectionList, NSError> {
        switch type {
        case .Artists:
            return self.getArtists()
        case .Albums:
            return self.getAlbums()
        case .Playlists:
            return self.getPlaylists()
        }
    }
    
    func getArtists() -> SignalProducer<TrackCollectionList, NSError> {
        return SignalProducer {
            sink, disposable in
            let sink = sink

            self.getSavedTracks().start({ (event) -> () in
                if let tracks = event.value {
                    var artists:[SPTPartialArtist] = []
                    for track in tracks {
                        artists.extend(track.artists as! [SPTPartialArtist])
                    }
                    let artistItems:[TrackCollection] = artists.map({ (artist) -> TrackCollection in
                        return SpotifyArtist(partialArtist: artist)
                    })
                    var filteredArtists:[TrackCollection] = []
                    for item in artistItems {
                        if filteredArtists.index(item) == nil {
                            filteredArtists.append(item)
                        }
                    }
                    let collectionList = TrackCollectionList(list: List(items: filteredArtists, totalCount: UInt(artistItems.count), pageNumber: 0))
                    sendNext(sink, collectionList)
                    sendCompleted(sink)
                }
            })
        }
    }
    
    func getAlbums() -> SignalProducer<TrackCollectionList, NSError> {
        return SignalProducer {
            sink, disposable in
            let sink = sink
        self.getSavedTracks().start( { (event) -> Void in
            if let tracks = event.value {
                let albums:[TrackCollection] = tracks.map({ (track) -> TrackCollection in
                    return SpotifyAlbum(partialAlbum: track.album)
                })
                var filteredAlbums:[TrackCollection] = []
                for item in albums {
                    if filteredAlbums.index(item) == nil {
                        filteredAlbums.append(item)
                    }
                }
                let collectionList = TrackCollectionList(list: List(items: filteredAlbums, totalCount: UInt(albums.count), pageNumber: 0))
                sendNext(sink, collectionList)
                sendCompleted(sink)
            }
            })
        }
    }
    
    func getPlaylists() -> SignalProducer<TrackCollectionList, NSError> {
        return SignalProducer {
            sink, disposable in
            spotify({ (token) -> Void in
                SPTPlaylistList.playlistsForUserWithSession(_spotifyController.session!, callback: { (error, list) -> Void in
                    if let list = list as? SPTPlaylistList {
                        if let items = list.items as? [SPTPartialPlaylist] {
                            let playlists:[TrackCollection] = items.map({ (playlist) -> TrackCollection in
                                return SpotifyPlaylist(partialPlaylist: playlist)
                            })
                            let itemList = List(items: playlists, totalCount: UInt(playlists.count), pageNumber: 0)
                            let colList = TrackCollectionList(list: itemList)
                            sendNext(sink, colList)
                            sendCompleted(sink)
                        } else {
                            sendError(sink, NSError(domain: kSpotifyErrorDomain, code: 0, userInfo: nil))
                            sendCompleted(sink)
                        }
                    } else {
                        sendError(sink, NSError(domain: kSpotifyErrorDomain, code: 0, userInfo: nil))
                        sendCompleted(sink)
                    }
                })
                }) { () -> Void in
                    sendError(sink, NSError(domain: kSpotifyErrorDomain, code: 0, userInfo: nil))
                    sendCompleted(sink)
            }
        }
    }
    
    func getSavedTracks() -> SignalProducer<[SPTPartialTrack], NSError> {
        return SignalProducer {
            sink, disposable in
            spotify({ (token) -> Void in
                SPTYourMusic.savedTracksForUserWithAccessToken(token, callback: { (error, obj) -> Void in
                    if let list = obj as? SPTListPage {
                        guard let _ = list.items as? [SPTPartialTrack] else {
                            sendNext(sink, [])
                            sendCompleted(sink)
                            return
                        }
                        sendNext(sink, list.items as! [SPTPartialTrack])
                        sendCompleted(sink)
                    } else {
                        sendError(sink, NSError(domain: kSpotifyErrorDomain, code: 0, userInfo: nil))
                        sendCompleted(sink)
                    }
                })

                }) { () -> Void in
                    sendError(sink, NSError(domain: kSpotifyErrorDomain, code: 0, userInfo: nil))
                    sendCompleted(sink)
            }
            
        }
        
    }
}
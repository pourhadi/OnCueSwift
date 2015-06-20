//
//  SpotifyModels.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/17/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import ReactiveCocoa

internal class SpotifyTrack: TrackItem {
    var source:ItemSource { return .Spotify }
    
    private var partialTrack:SPTPartialTrack
    private var fullTrack:SPTTrack?
    
    init(partialTrack:SPTPartialTrack) {
        self.partialTrack = partialTrack
    }
    
    var title:String? { return self.partialTrack.name }
    
    var subtitle:String? {
        var artists:[String] = self.partialTrack.artists.map { (artist) -> String in
            let artist = artist as! SPTPartialArtist
            return artist.name
        }
        return subtitleString(artists, self.partialTrack.album.name)
    }
    
    var identifier:String { return self.partialTrack.identifier }
    
    func getImage(forSize:CGSize, complete:(image:UIImage)->Void) {
        
    }
    
    var cellReuseID:String { return "textCell" }
    
    var duration:NSTimeInterval {
        return self.partialTrack.duration
    }
    
    var itemType:ItemType { return .Track }
    
}

internal class SpotifyTrackCollection : TrackCollection {
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        
    }
}

internal class SpotifyAlbum : SpotifyTrackCollection, AlbumItem {
    var itemType:ItemType { return .Album }
    var source:ItemSource { return .Spotify }
    
    private var partialAlbum:SPTPartialAlbum
    private var fullAlbum:SPTAlbum?
    
    init(partialAlbum:SPTPartialAlbum) {
        self.partialAlbum = partialAlbum
    }
    
    var title:String? { return self.partialAlbum.name }
    var subtitle:String? { return nil }
    
    var identifier:String { return self.partialAlbum.identifier }
    var cellReuseID:String { return "textCell" }
    
    typealias T = SpotifyTrack
    func getTracks(page: Int, complete: (list: List<SpotifyTrack>?) -> Void) {
        SPTAlbum.albumWithURI(self.partialAlbum.uri, accessToken: _spotifyController.token!, market: nil) { (error, album) -> Void in
            if error == nil {
                var items = album.firstTrackPage!.items as! [SPTPartialTrack]
                var listItems:[SpotifyTrack] = []
                for track in items {
                    listItems.append(SpotifyTrack(partialTrack: track))
                }
                var itemList = List(items: listItems, totalCount:album.firstTrackPage!.totalListLength, pageNumber:page)
                complete(list: itemList)
            }
        }
    }
    
    func getImage(forSize: CGSize, complete: (image: UIImage) -> Void) {
        
    }
}

internal class SpotifyArtist : SpotifyTrackCollection, ArtistItem {
    var itemType:ItemType { return .Artist }
    var source:ItemSource { return .Spotify }
    
    private var partialArtist:SPTPartialArtist
    private var fullArtist:SPTArtist?
    
    init(partialArtist:SPTPartialArtist) {
        self.partialArtist = partialArtist
    }
    
    var title:String? { return self.partialArtist.name }
    var subtitle:String? { return nil }
    
    var identifier:String { return self.partialArtist.identifier }
    var cellReuseID:String { return "textCell" }
    
    typealias T = SpotifyTrack
    func getTracks(page: Int, complete: (list: List<SpotifyTrack>?) -> Void) {
        SPTArtist.artistWithURI(self.partialArtist.uri, accessToken: _spotifyController.token!) { (error, artist) -> Void in
            if error == nil {
                var items = artist.firstTrackPage!.items as! [SPTPartialTrack]
                var listItems:[SpotifyTrack] = []
                for track in items {
                    listItems.append(SpotifyTrack(partialTrack: track))
                }
                var itemList = List(items: listItems, totalCount:artist.firstTrackPage!.totalListLength, pageNumber:page)
                complete(list: itemList)
            }
        }
    }
    
    func getAlbums<T:AlbumItem>(page: Int, complete: (albums: List<T>?) -> Void) {
        
    }
    
    func getImage(forSize: CGSize, complete: (image: UIImage) -> Void) {
        
    }
    
}

internal class SpotifyPlaylist : SpotifyTrackCollection, PlaylistItem {
    var itemType:ItemType { return .Playlist }
    var source:ItemSource { return .Spotify }
    
    private var partialPlaylist:SPTPartialPlaylist
    private var fullPlaylist:SPTPlaylistSnapshot?
    
    init(partialPlaylist:SPTPartialPlaylist) {
        self.partialPlaylist = partialPlaylist
    }
    
    var title:String? { return self.partialPlaylist.name }
    var subtitle:String? { return nil }
    
    var identifier:String { return self.partialPlaylist.uri.absoluteString! }
    var cellReuseID:String { return "textCell" }
    
    typealias T = SpotifyTrack
    override func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        SPTPlaylistSnapshot.playlistWithURI(self.partialPlaylist.uri, accessToken: _spotifyController.token!) { (error, album) -> Void in
            if error == nil {
                var items = album.firstTrackPage!.items as! [SPTPartialTrack]
                var listItems:[TrackItem] = []
                for track in items {
                    listItems.append(SpotifyTrack(partialTrack: track))
                }
                var itemList = List(items: listItems, totalCount:album.firstTrackPage!.totalListLength, pageNumber:page)
                complete(list: itemList)
            }
        }
    }
    
    func getImage(forSize: CGSize, complete: (image: UIImage) -> Void) {
        
    }
}

class SpotifyManager: ItemManager {
    
    func getHomeVM(complete:(vm:ListVM)->Void) {
        spotify { (token) -> Void in
            SPTPlaylistList.playlistsForUserWithSession(_spotifyController.session!, callback: { (error, list) -> Void in
                if let list = list as? SPTPlaylistList {
                    let items = list.items as! [SPTPartialPlaylist]
                    var playlists:[TrackCollection] = []
                    for item in items {
                        playlists.append(SpotifyPlaylist(partialPlaylist: item))
                    }
                    
                    let itemList = List<TrackCollection>(items:playlists, totalCount:UInt(playlists.count), pageNumber:0)
                    let collectionList = TrackCollectionList(list: itemList)
                    let listVM = ListVM(list: collectionList, grouped: false, delegate:self)
                    self.homeVM = listVM
                    complete(vm:listVM)
                }
            })
        }
    }
    
}

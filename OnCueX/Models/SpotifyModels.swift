//
//  SpotifyModels.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/17/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

internal class SpotifyTrack: TrackItem {
    var source:ItemSource { return .Spotify }
    
    private var partialTrack:SPTPartialTrack
    private var fullTrack:SPTTrack?
    
    init(partialTrack:SPTPartialTrack) {
        self.partialTrack = partialTrack
    }
    
    var title:String? { return self.partialTrack.name }
    
    var subtitle:String? {
        let artists:[String] = self.partialTrack.artists.map { (artist) -> String in
            let artist = artist as! SPTPartialArtist
            return artist.name
        }
        return subtitleString(artists, album: self.partialTrack.album.name)
    }
    
    var identifier:String { return self.partialTrack.identifier }
    
    func getImage(forSize:CGSize, complete:(image:UIImage?)->Void) {
        _imageController.getImage(self.partialTrack.album.smallestCover.imageURL) { (url, image) -> Void in
            complete(image:image)
        }
    }
    
    var cellReuseID:String { return "textCell" }
    
    var duration:NSTimeInterval {
        return self.partialTrack.duration
    }
    
    var itemType:ItemType { return .Track }
    
}

internal class SpotifyAlbum : AlbumItem {
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
    
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        SPTAlbum.albumWithURI(self.partialAlbum.uri, accessToken: _spotifyController.token!, market: nil) { (error, album) -> Void in
            if error == nil {
                let items = album.firstTrackPage!.items as! [SPTPartialTrack]
                var listItems:[TrackItem] = []
                for track in items {
                    listItems.append(SpotifyTrack(partialTrack: track))
                }
                let itemList = List(items: listItems, totalCount:album.firstTrackPage!.totalListLength, pageNumber:page)
                complete(list: itemList)
            }
        }
    }
    
    func getImage(forSize: CGSize, complete: (image: UIImage?) -> Void) {
        
    }
}

internal class SpotifyArtist : ArtistItem {
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
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        SPTArtist.artistWithURI(self.partialArtist.uri, accessToken: _spotifyController.token!) { (error, artist) -> Void in
            if error == nil {
                let items = artist.firstTrackPage!.items as! [SPTPartialTrack]
                var listItems:[TrackItem] = []
                for track in items {
                    listItems.append(SpotifyTrack(partialTrack: track))
                }
                let itemList = List(items: listItems, totalCount:artist.firstTrackPage!.totalListLength, pageNumber:page)
                complete(list: itemList)
            }
        }
    }
    
    func getAlbums<T:AlbumItem>(page: Int, complete: (albums: List<T>?) -> Void) {
        
    }
    
    func getImage(forSize: CGSize, complete: (image: UIImage?) -> Void) {
        
    }
    
}

internal class SpotifyPlaylist : PlaylistItem {
    var itemType:ItemType { return .Playlist }
    var source:ItemSource { return .Spotify }
    
    private var partialPlaylist:SPTPartialPlaylist
    private var fullPlaylist:SPTPlaylistSnapshot?
    
    init(partialPlaylist:SPTPartialPlaylist) {
        self.partialPlaylist = partialPlaylist
    }
    
    var title:String? { return self.partialPlaylist.name }
    var subtitle:String? { return nil }
    
    var identifier:String { return self.partialPlaylist.uri.absoluteString }
    var cellReuseID:String { return "textCell" }
    
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        SPTPlaylistSnapshot.playlistWithURI(self.partialPlaylist.uri, accessToken: _spotifyController.token!) { (error, album) -> Void in
            if error == nil {
                let items = album.firstTrackPage!.items as! [SPTPartialTrack]
                var listItems:[TrackItem] = []
                for track in items {
                    listItems.append(SpotifyTrack(partialTrack: track))
                }
                let itemList = List(items: listItems, totalCount:album.firstTrackPage!.totalListLength, pageNumber:page)
                complete(list: itemList)
            }
        }
    }
    
    func getImage(forSize: CGSize, complete: (image: UIImage?) -> Void) {
        
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
                    let displayContext = CustomDisplayContext("Playlists")
                    let listVM = ListVM(list: collectionList, displayContext:displayContext, grouped: false, delegate:self)
                    self.homeVM = listVM
                    complete(vm:listVM)
                }
            })
        }
    }
    
}

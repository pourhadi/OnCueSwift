//
//  LibraryItem.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/27/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import MediaPlayer
import ReactiveCocoa

extension MPMediaItem {
    func getImage(forSize:CGSize, complete:(image:UIImage?)->Void) {
        let artwork = self.artwork
        if let artwork = artwork {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                let img = artwork.imageWithSize(forSize)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    complete(image:img)
                })
            })
        }
    }
}

internal struct LibraryTrack: TrackItem, Queueable {
    var assetURL:NSURL {
        return self.mediaItem.assetURL!
    }
    
    var source:ItemSource { return .Library }
    
    private var mediaItem:MPMediaItem
    
    init(mediaItem:MPMediaItem) {
        self.mediaItem = mediaItem
    }
    
    var title:String? { return self.mediaItem.title }
    
    var subtitle:String? {
        let artist = self.mediaItem.artist
        let album = self.mediaItem.albumTitle
        return "\(String(self.duration)) - " + subtitleString(artist == nil ? nil : [artist!], album: album)
    }
    
    var isTrackCollection = false
    
    var identifier:String { return "\(self.mediaItem.persistentID)" }
    
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        self.mediaItem.getImage(forSize) { (image) -> Void in
            complete(context: self, image: image)
        }
    }
    
    var cellReuseID:String { return "textCell" }
    
    var duration:NSTimeInterval {
        return self.mediaItem.playbackDuration
    }
    
    var itemType:ItemType { return .Track }
    
    var isContainer:Bool { return false }
    func getTracks(complete: (tracks: [TrackItem]) -> Void) {
        complete(tracks:[self])
    }
}

internal struct LibraryAlbum : AlbumItem {
    var itemType:ItemType { return .Album }
    var source:ItemSource { return .Library }
    
    private var collection:MPMediaItemCollection
    private var representativeItem:MPMediaItem {
        return self.collection.representativeItem!
    }
    
    init(collection:MPMediaItemCollection) {
        self.collection = collection
    }
    
    var title:String? { return self.representativeItem.albumTitle }
    var subtitle:String? { return nil }
    
    var isTrackCollection = true
    
    var identifier:String { return "\(self.representativeItem.albumPersistentID)" }
    var cellReuseID:String { return "textCell" }
    
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        var items:[TrackItem] = []
        for item in self.collection.items {
            items.append(LibraryTrack(mediaItem: item))
        }
        complete(list:List(items: items, totalCount: UInt(items.count), pageNumber: 0))
    }
    
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        self.representativeItem.getImage(forSize) { (image) -> Void in
            complete(context:self, image:image)
        }
    }
    
    var numberOfItemsInStack:Int = 0
}

extension AlbumItem {
    func getImagesForStack(size:CGSize, complete:(context:StackedImageViewDataSource, images:[UIImage])->Void) {
        self.getImage(size) { (context, image) -> Void in
            guard let image = image else { return }
            complete(context: self, images: [image])
        }
    }
}

internal struct LibraryArtist : ArtistItem {
    var itemType:ItemType { return .Artist }
    var source:ItemSource { return .Library }
    
    private var collection:MPMediaItemCollection
    private var representativeItem:MPMediaItem {
        return self.collection.representativeItem!
    }
    
    init(collection:MPMediaItemCollection) {
        self.collection = collection
    }
    
    var title:String? { return self.representativeItem.artist }
    var subtitle:String? { return nil }
    
    var isTrackCollection = true
    
    var identifier:String { return "\(self.representativeItem.artistPersistentID)" }
    var cellReuseID:String { return "textCell" }
    
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        var items:[TrackItem] = []
        for item in self.collection.items {
            items.append(LibraryTrack(mediaItem: item))
        }
        complete(list:List(items: items, totalCount: UInt(items.count), pageNumber: 0))
    }
    
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        self.representativeItem.getImage(forSize) { (image) -> Void in
            complete(context:self, image:image)
        }
    }
    
    func getAlbums(page: Int, complete: (albums: List<TrackCollection>?) -> Void) {
        let query = MPMediaQuery.albumsQuery()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(unsignedLongLong:  self.representativeItem.artistPersistentID), forProperty: MPMediaItemPropertyArtistPersistentID))
        
        if let collections = query.collections {
            var albums:[TrackCollection] = []
            for collection in collections {
                albums.append(LibraryAlbum(collection: collection))
            }
            complete(albums: List(items: albums, totalCount: UInt(albums.count), pageNumber: 0))
        }
    }
    
    
    

    var numberOfItemsInStack:Int {
        let query = MPMediaQuery.albumsQuery()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(unsignedLongLong:  self.representativeItem.artistPersistentID), forProperty: MPMediaItemPropertyArtistPersistentID))
        
        if let collections = query.collections {
            return collections.count
        }
        return 0
    }
}

extension ArtistItem {
    func getImagesForStack(size:CGSize, complete:(context:StackedImageViewDataSource, images:[UIImage])->Void) {
        self.getAlbums(0) { (albums) -> Void in
            guard let albums = albums else { complete(context: self, images: []); return }
            let sp:SignalProducer = SignalProducer<SignalProducer<UIImage, NoError>, NoError> { event, _ in
                for album in albums.items {
                    sendNext(event, album.getImage(size))
                }
                sendCompleted(event)
            }
            
            sp
                |> flatten(FlattenStrategy.Concat)
                |> collect
                |> start({ event in
                    complete(context:self, images:event.value != nil ? event.value! : [])
                })
        }
    }
}

internal struct LibraryPlaylist : PlaylistItem {
    var itemType:ItemType { return .Playlist }
    var source:ItemSource { return .Library }
    
    private var playlist:MPMediaPlaylist
    
    init(playlist:MPMediaPlaylist) {
        self.playlist = playlist
    }
    
    var title:String? { return self.playlist.name }
    var subtitle:String? { return nil }
    
    var isTrackCollection = true
    
    var identifier:String { return "\(self.playlist.persistentID)" }
    var cellReuseID:String { return "textCell" }
    
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        var items:[TrackItem] = []
        for item in self.playlist.items {
            items.append(LibraryTrack(mediaItem: item))
        }
        complete(list:List(items: items, totalCount: UInt(items.count), pageNumber: 0))
    }
    
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        
    }
    
    func getImagesForStack(size:CGSize, complete:(context:StackedImageViewDataSource, images:[UIImage])->Void) {
        
    }
    
    var numberOfItemsInStack:Int = 0
}



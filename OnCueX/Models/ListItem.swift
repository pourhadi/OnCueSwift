//
//  LibraryItem.swift
//  
//
//  Created by Daniel Pourhadi on 6/17/15.
//
//

import UIKit
import ReactiveCocoa

enum ItemSource:String, Identifiable {
    case Library = "Library"
    case Spotify = "Spotify"
    
    var identifier:String {
        return self.rawValue
    }
}

enum ItemType:String {
    case Artist = "Artist"
    case Album = "Album"
    case Playlist = "Playlist"
    case Track = "Track"
}

/* generic base for all items */
protocol Item:DisplayContext, Identifiable {
    var source:ItemSource { get }
    var cellReuseID:String { get }
    var itemType:ItemType { get }
}

/* for individual tracks */
protocol TrackItem : Item, Playable { var duration:NSTimeInterval { get } }

/* for groups of tracks */
protocol TrackCollection: Item, StackedImageViewDataSource {
    func getTracks(page:Int, complete:(list:List<protocol<TrackItem>>?)->Void)
}

/* more narrow group definitions */
protocol AlbumItem: TrackCollection {}

protocol ArtistItem : TrackCollection {
    func getAlbums(page:Int, complete:(albums:List<TrackCollection>?)->Void)
}

protocol PlaylistItem : TrackCollection {}

extension TrackCollection {
    var isTrackCollection:Bool {
        return true
    }
}

/* identifying items */
protocol Identifiable {
    var identifier:String { get }
}

extension Identifiable {
    func isEqual(other:Identifiable) -> Bool {
        return self.identifier == other.identifier
    }
}


/* for displaying */
protocol ImageSource:Identifiable {
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void)
}

extension ImageSource {
    func getImage(forSize:CGSize) -> SignalProducer<UIImage, NoError> {
        return SignalProducer {
            sink, disposable in
            self.getImage(forSize, complete: { (context, image) -> Void in
                sendNext(sink, image != nil ? image! : UIImage())
                sendCompleted(sink)
            })
        }
    }
}

protocol DisplayContext:ImageSource {
    var title:String? { get }
    var subtitle:String? { get }
    var isTrackCollection:Bool { get }
}

struct CustomDisplayContext: DisplayContext {
    var title:String?
    var subtitle:String?
    var isTrackCollection = false
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {}
    
     init(_ title:String) {
        self.title = title
    }

    var identifier:String = {
       return NSUUID().UUIDString
    }()
    
    mutating func setSubtitle(subtitle:String?) {
        self.subtitle = subtitle
    }
}

class List<T> {
    var items:[T]
    var totalCount:UInt
    var pageNumber:Int
    
    init(items:[T], totalCount:UInt, pageNumber:Int) {
        self.items = items
        self.totalCount = totalCount
        self.pageNumber = pageNumber
    }

    convenience init(items:[T], totalCount:Int, pageNumber:Int) {
        self.init(items:items, totalCount:UInt(totalCount), pageNumber:pageNumber)
    }
    
    func objectAtIndexPath(path:NSIndexPath) -> T {
        return self.items[path.row]
    }
}

public func subtitleString(artists:[String]?, album:String?) -> String {
    var string:String = ""
    if let artists = artists {
        if artists.count > 0 {
            string = artists[0]
        }
    }
    if let album = album {
        if string.characters.count > 0 {
            string += " - \(album)"
        } else {
            string += " \(album)"
        }
    }
    return string
}

protocol ItemViewModelObserver: class {
    func queueIndexUpdate(viewModel:ItemViewModel, queueIndex:QueueIndex?)
}

class ItemViewModel: DisplayContext, QueueObserver {
    
    weak var observer:ItemViewModelObserver?
    var queueIndex:QueueIndex? {
        didSet {
            if let observer = self.observer {
                observer.queueIndexUpdate(self, queueIndex: self.queueIndex)
            }
        }
    }
    
    var identifier:String {
        return "\(self.item.identifier)_vm"
    }
    
    let item:Item
    
    init(item:Item) {
        self.item = item
        _queue.addObserver(self)
    }
    
    deinit {
        _queue.removeObserver(self)
        print("item view model deinit")
    }
    
    var title:String? { return self.item.title }
    var subtitle:String? { return self.item.subtitle }
    var isTrackCollection:Bool { return self.item.isTrackCollection }
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        self.item.getImage(forSize, complete: complete)
    }
    
    func queueUpdated(queue:Queue) {
        self.queueIndex = _queue.indexOfItem(self.item)
    }
}


protocol ItemList {
    var items:[ItemViewModel] { get }
    var totalCount:UInt { get }
    var currentOffset:Int { get }
}

class TrackList : ItemList {
    
    let list:List<TrackItem>
    init(list:List<TrackItem>) {
        self.list = list
        var newItems:[ItemViewModel] = []
        for trackItem in self.list.items {
            newItems.append(ItemViewModel(item: trackItem))
        }
        self.items = newItems
    }
    
    var items:[ItemViewModel]
    
    var totalCount:UInt {
        return self.list.totalCount
    }
    
    var currentOffset:Int {
        return self.list.pageNumber
    }
    
    deinit {
        print("tracklist deinit")
    }
}

class TrackCollectionList : ItemList {
    let list:List<TrackCollection>
    init(list:List<TrackCollection>) {
        self.list = list
        var newItems:[ItemViewModel] = []
        for trackItem in self.list.items {
            newItems.append(ItemViewModel(item:trackItem as Item))
        }
        self.items = newItems
    }
    
    var items:[ItemViewModel]
    
    var totalCount:UInt {
        return self.list.totalCount
    }
    
    var currentOffset:Int {
        return self.list.pageNumber
    }
    
    deinit {
        print("TrackCollectionList deinit")
    }
}


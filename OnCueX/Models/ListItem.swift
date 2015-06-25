//
//  LibraryItem.swift
//  
//
//  Created by Daniel Pourhadi on 6/17/15.
//
//

import UIKit
//import ReactiveCocoa

enum ItemSource {
    case Library
    case Spotify
}

enum ItemType {
    case Artist
    case Album
    case Playlist
    case Track
}

protocol Identifiable {
    var identifier:String { get }
}

extension Identifiable {
    func isEqual(other:Identifiable) -> Bool {
        return self.identifier == other.identifier
    }
}

protocol ImageSource:Identifiable {
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void)
}

protocol Item:ImageSource, DisplayContext, Identifiable {
    var source:ItemSource { get }
    var cellReuseID:String { get }
    var itemType:ItemType { get }
}

protocol TrackCollection: DisplayContext {
    func getTracks(page:Int, complete:(list:List<protocol<TrackItem>>?)->Void)
}

protocol AlbumItem: TrackCollection, Item {}

protocol ArtistItem : TrackCollection, Item {
    func getAlbums<T:AlbumItem>(page:Int, complete:(albums:List<T>?)->Void)
}

protocol PlaylistItem : TrackCollection, Item {}

protocol TrackItem : Item { var duration:NSTimeInterval { get } }

protocol DisplayContext:ImageSource {
    var title:String? { get }
    var subtitle:String? { get }
}

struct CustomDisplayContext: DisplayContext {
    var title:String?
    var subtitle:String?
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {}
    
     init(_ title:String) {
        self.init()
        self.title = title
    }
    
    init() {}
    
    var identifier:String = {
       return NSUUID().UUIDString
    }()
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

protocol ItemManagerDelegate: class {
    func itemManager(itemManager:ItemManager, pushVCForVM:ListVM)
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
            newItems.append(ItemViewModel(item:trackItem as! Item))
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

class ItemManager: ListVMDelegate {
    unowned var delegate:ItemManagerDelegate
    
    init(delegate:ItemManagerDelegate) {
        self.delegate = delegate
    }
    
    var homeVM:ListVM? {
        didSet {
            if let vm = self.homeVM {
//                vm.itemSelectedSignal.subscribeNext { [weak self] (val) -> Void in
//                    if let this = self {
//                        var playlist = val as! SpotifyPlaylist
//                            playlist.getTracks(0, complete: { (list) -> Void in
//                                if let list = list {
//                                    let trackList = TrackList(list: list)
//                                    let itemVM = ListVM(list: trackList, grouped: false, delegate:this)
//                                    this.delegate.itemManager(this, pushVCForVM: itemVM)
//                                }
//                            })
//                        
//                    }
//                }
            }
        }
    }
    
    func listVM(listVM:ListVM, selectedItem:protocol<Item>, deselect:(deselect:Bool)->Void) {
        if let item = selectedItem as? TrackCollection {
            item.getTracks(0, complete: { (list) -> Void in
                if let list = list {
                    let trackList = TrackList(list: list)
                    let itemVM = ListVM(list: trackList, displayContext:item, grouped: false, delegate:self)
                    self.delegate.itemManager(self, pushVCForVM: itemVM)
                }
            })
            deselect(deselect: false)

        } else if let item = selectedItem as? Queueable {
            _queue.insert(item, complete: nil)
            deselect(deselect: true)

        }
    }
}

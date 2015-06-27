//
//  ItemProvider.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/27/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

enum ProviderCollectionType {
    case Artists
    case Albums
    case Playlists
    case AlbumsForArtist
}

protocol ItemProviderProtocol {
    func getCollections(type:ProviderCollectionType, filterContext:AnyObject?, complete:(collections:TrackCollectionList?)->Void)
}

class SpotifyItemProvider:ItemProviderProtocol {
    
    func getCollections(type:ProviderCollectionType, filterContext:AnyObject?, complete:(collections:TrackCollectionList?)->Void) {
        switch type {
        case .Playlists:
            self.getPlaylists(complete)
        default:
            complete(collections: nil)
        }
    }
    
    func getPlaylists(complete:(collections:TrackCollectionList?)->Void) {
        SPTPlaylistList.playlistsForUserWithSession(_spotifyController.session!, callback: { (error, list) -> Void in
            if let list = list as? SPTPlaylistList {
                let items = list.items as! [SPTPartialPlaylist]
                var playlists:[TrackCollection] = []
                for item in items {
                    playlists.append(SpotifyPlaylist(partialPlaylist: item))
                }
                
                let itemList = List<TrackCollection>(items:playlists, totalCount:UInt(playlists.count), pageNumber:0)
                let collectionList = TrackCollectionList(list: itemList)
                complete(collections: collectionList)
            }
        })
    }
}

class ItemManager: ListVMDelegate {
    unowned var delegate:ItemManagerDelegate
    
    init(delegate:ItemManagerDelegate) {
        self.delegate = delegate
    }
    
    var homeVM:ListVM?
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
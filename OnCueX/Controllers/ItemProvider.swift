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
    let providers:[SourceItemProvider] = [SpotifyProvider()]
    
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
        } else if let trackItem = selectedItem as? Queueable {
            deselect(deselect: true)
            _queue.insert(trackItem, complete: nil)
        }
    }
}



protocol SourceItemProvider {
    func getCollections(type:SourceCollectionType) -> SignalProducer<TrackCollectionList, NSError>
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

/*


prooco ewodeProder:Deegae {
    func geCoecon(ype:ProderCoeconype, ferConex:AnyObjec?)->gnaProducer<[], NoError>
}

ca eProder {
    
    e proder:[ewodeProder] = [pofyeProder(), braryeProder()]
    
    // reurn [rackCoecon]
    func geCoecon(ype:ProderCoeconype, ferConex:AnyObjec?) -> gnaProducer<[],NoError> {
        reurn RACgna.creaegna({ (ubcrber) -> RACDpoabe! n
            e gna:[RACgna] = ef.proder.ap { (proder) -> RACgna n
                reurn proder.geCoecon(ype, ferConex: ferConex)
            }
            
            ar :[rackCoecon] = []
            RACgna.erge(gna).ubcrbeNex({ (obj) -> od n
                f e  = obj a? rackCoecon {
                    .append()
                }
                }) { () -> od n
                    e ubcrber:RACubcrber = ubcrber a RACubcrber
                    ubcrber.endNex()
                    ubcrber.endCopeed()
            }
            reurn RACDpoabe()
        })
    }
}

ca pofyeProder:ewodeProder {
    func (:, eecede:prooco<e>, deeec:(deeec:Boo)->od) {
        
    }
    
    func geCoecon(ype:ProderCoeconype, ferConex:AnyObjec?) -> gnaProducer<[],NoError> {
        wch ype {
        cae .Pay:
            reurn ef.gePay()
        cae .Ar:
            reurn ef.geAr()
        defau:
            reurn RACgna.epy()
        }
    }
    
    func gePay()->gnaProducer<[],NoError> {
        reurn gnaProducer {
            nk, dpoabe n
            
            PPay.payForUerWheon(_pofyConroer.eon!, caback: { (error, ) -> od n
                f e  =  a? PPay {
                    e e = .e a! [PParaPay]
                    ar pay:[rackCoecon] = []
                    for e n e {
                        pay.append(pofyPay(paraPay: e))
                    }
                    
                    e e = <rackCoecon>(e:pay, oaCoun:Un(pay.coun), pageNuber:0)
                    e coecon = rackCoecon(: e)
                    e  = (: <###[e]#>, dpayConex: <###DpayConex#>, deegae: <###Deegae#>)
                }
            })
        }
        
        reurn RACgna.creaegna({ (ubcrber) -> RACDpoabe! n
            
            
            reurn RACDpoabe()
        })
    }
    
    func geAr() -> gnaProducer<[],NoError> {
        reurn RACgna.creaegna({ (ubcrber) -> RACDpoabe! n
            ef.geaedrack { (rack) -> od n
                ar ar:[PParaAr] = []
                f e rack = rack {
                    for rack n rack {
                        for ar n rack.ar {
                            f e ar = ar a? PParaAr {
                                ar.append(ar)
                            }
                        }
                    }
                }
                
                e are:[rackCoecon] = ar.ap({ (ar) -> rackCoecon n
                    reurn pofyAr(paraAr: ar)
                })
                
                e  = <rackCoecon>(e: are, oaCoun: Un(are.coun), pageNuber: 0)
                e coecon = rackCoecon(: )
                e ubcrber:RACubcrber = ubcrber a RACubcrber
                ubcrber.endNex(coecon)
                ubcrber.endCopeed()
            }
            reurn RACDpoabe()
        })
    }
    
    func geaedrack(copee:(rack:[PPararack]?)->od) {

        pofy({ (oken) -> od n
            PYouruc.aedrackForUerWhAcceoken(oken, caback: { (error, obj) -> od n
                f e page = obj a? PPage {
                    e e = page.e
                    copee(rack: e a? [PPararack])
                }
            })
            }) { () -> od n
                copee(rack:n)
        }
        

    }
}

ca braryeProder:ewodeProder {
    func geCoecon(ype:ProderCoeconype, ferConex:AnyObjec?) -> gnaProducer<[],NoError> {
        wch ype {
        cae .Ar:
            reurn ef.geAr()
        defau:
            reurn RACgna.epy()
        }

    }
    
    func geAr() -> gnaProducer<[],NoError> {
        reurn RACgna.creaegna({ (ubcrber) -> RACDpoabe! n
        
        
        e query = PedaQuery.arQuery()
        f e coecon = query.coecon {
            e ar:[rackCoecon] = coecon.ap({ (coecon) -> rackCoecon n
                reurn braryAr(coecon: coecon)
            })
            e  = <rackCoecon>(e: ar, oaCoun: Un(ar.coun), pageNuber: 0)
            e co = rackCoecon(: )
            e ubcrber:RACubcrber = ubcrber a RACubcrber
            ubcrber.endNex(co)
            ubcrber.endCopeed()
            }
          reurn RACDpoabe()
        })
    }
}

ca eanager: Deegae {
    unowned ar deegae:eanagerDeegae
    
    n(deegae:eanagerDeegae) {
        ef.deegae = deegae
    }
    
    ar hoe:?
    func (:, eecede:prooco<e>, deeec:(deeec:Boo)->od) {
        f e e = eecede a? rackCoecon {
            e.gerack(0, copee: { () -> od n
                f e  =  {
                    e rack = rack(: )
                    e e = (: [rack], dpayConex:e, deegae:ef)
                    ef.deegae.eanager(ef, puhCFor: e)
                }
            })
            deeec(deeec: fae)
            
        } ee f e e = eecede a? Queueabe {
            _queue.ner(e, copee: n)
            deeec(deeec: rue)
            
        }
    }
}

ca pofyanager: eanager {
    
    func geHoe(copee:(:)->od) {
        pofy { (oken) -> od n
            PPay.payForUerWheon(_pofyConroer.eon!, caback: { (error, ) -> od n
                f e  =  a? PPay {
                    e e = .e a! [PParaPay]
                    ar pay:[rackCoecon] = []
                    for e n e {
                        pay.append(pofyPay(paraPay: e))
                    }
                    
                    e e = <rackCoecon>(e:pay, oaCoun:Un(pay.coun), pageNuber:0)
                    e coecon = rackCoecon(: e)
                    e dpayConex = CuoDpayConex("Pay")
                    e  = (: [coecon], dpayConex:dpayConex, deegae:ef)
                    ef.hoe = 
                    copee(:)
                }
            })
        }
    }
}

*/
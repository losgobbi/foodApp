//
//  ScrollRecycler.swift
//  FoodApp
//
//  Created by Rodrigo Celso Gobbi on 10/28/15.
//  Copyright © 2015 Hagen. All rights reserved.
//
//  Scrollview recycler
//

import UIKit
import Foundation

func dbgRec(message: String, function: String = #function) {
    #if DEBUG_RECYCLER
    print("\(function)> " + message)
    #endif
}

class ScrollRecycler {
    
    /* Scrolling pointers */
    private var triggerAsc: Int = 0
    private var triggerDesc: Int = 0
    
    /* How many pages will be recycled */
    private var recycleNum: Int = recycleNumber
    
    /* Pages for recycler */
    private var currentPage: Int = 0
    private var recycledPages = [ProductView]()
    private var visiblePages = [ProductView]()

    /* Controller for this recycler, we need to access its subviews */
    private var vc: ViewController?
    
    /* The scrollview and its content size */
    private var scrollMenu: UIScrollView?
    private var scrollMenuSize: Int = 0
    
    /* Init scroll information */
    func recInit(viewController: ViewController, scrollView: UIScrollView,
        scrollSize: Int) {
            vc = viewController
            scrollMenu = scrollView
            scrollMenuSize = scrollSize
    }
    
    /* Add page to recycle control */
    func recAddPage(pdView: ProductView) {
        visiblePages.append(pdView)
    }
    
    /* Update current page */
    func recUpdateCurrentPage(page: Int) {
        currentPage = page
    }
    
    func recGetCurrentPage() -> Int {
        return currentPage
    }
    
    /* Restart recycler, scroll was erased */
    func recRestart() {
        currentPage = 0
        
        visiblePages.removeAll(keepCapacity: false)
        recycledPages.removeAll(keepCapacity: false)
        
        triggerAsc = 0
        triggerDesc = 0
    }
    
    /* Scrollview did scroll */
    func recDidScroll() {
        let bounds = scrollMenu!.bounds
        let pageWidth = scrollMenu!.frame.size.width;
        let fractionalPage = scrollMenu!.contentOffset.x / pageWidth;
        let page = round(fractionalPage)
        let previousPage = vc?.getPreviousPage()
        if (vc?.getPreviousPage() != page) {
            vc?.setPreviousPage(page)
        }
        
        /* convert into int */
        var previousPg = Int(previousPage!)
        if previousPg < 0 {
            /* reached the minor value for scroll */
            previousPg = 0
        }
        let actualPg = Int(page)
        currentPage = actualPg
        
        dbgRec("CGRectGetMinX(bounds):\(CGRectGetMinX(bounds)) CGRectGetMaxX(bounds):\(CGRectGetMaxX(bounds)) CGRectGetWidth(bounds):\(CGRectGetWidth(bounds))")
        dbgRec("=================================")
        
        /* was page changed? (x-coordinate is changing) */
        if actualPg != previousPg {
            
            /* check if we can recycle */
            let cantRecycle = recReachedLimit(&recycleNum,
                side: actualPg < previousPg)
            
            if actualPg > previousPg {
                /* end of the scroll, cant recycle */
                if cantRecycle {
                    dbgRec("We reached the limit, cant recycle!")
                    return
                }
            }
            
            /* Update the trigger */
            recUpdateTrigger(previousPg, nextPage: actualPg)
            
            /*
            * Check if we are scrolling in the ascending direction.
            * If so, recycle views from the left border
            */
            if actualPg == triggerDesc && previousPg == triggerAsc {
                /* recyle */
                recRecyclePages("ascending", number: recycleNum)
                recDequeueRecyclePages("ascending", number: recycleNum)
                
                
                /* XXX update page at this point too */
                currentPage = Int(page)
            }
            
            /*
            * Check if we are scrolling in the descending direction.
            * If so, recycle views from the right border
            */
            if actualPg == triggerAsc && previousPg == triggerDesc {
                /* recyle */
                recRecyclePages("descending", number: recycleNum)
                recDequeueRecyclePages("descending", number: recycleNum)
                
                /* XXX update page at this point too */
                currentPage = Int(page)
            }
        }
    }
    
    /*
    * Check if currentPage/nextPage are in the correct position for recycle
    * algorithm. The trigger is always on the middle of the scroll.
    */
    func recUpdateTrigger(currentPage: Int, nextPage: Int) {
        let subviews = vc!.getProductSubViews()
        let centerPos = (subviews.count/2) - 1
        let width = scrollMenu!.frame.width
        
        let centerPdView = subviews[centerPos]
        let firstPdView = subviews[0]
        
        /* get the current origin position */
        let currentPageOrigin = CGFloat(Float(currentPage)) * width
        let centerPage = Int((centerPdView.frame.origin.x)/width)
        
        dbgRec("currentPage:\(currentPage) nextPage:\(nextPage) width:\(width) currentPageOrigin:\(currentPageOrigin) centerPdView.frame.origin.x:\(centerPdView.frame.origin.x) triggerAsc:\(triggerAsc) triggerDesc:\(triggerDesc) centerPos:\(centerPos) firstPdViewName:\(firstPdView.getProduct().name) centerPage:\(centerPage)")
        
        /* count the number of recycle pages */
        let recyclePagesCount = recycleNumber * Int(width)
        
        /* get the first pd view */
        var firstPdViewOriginX = 0
        if Int(firstPdView.frame.origin.x) > 0 {
            firstPdViewOriginX = Int(firstPdView.frame.origin.x) - recyclePagesCount
            if firstPdViewOriginX < 0 {
                firstPdViewOriginX = 0
            }
        }
        
        /* check the middle page */
        let middlePdView = (firstPdViewOriginX + (Int(width) * (scrollInitialNumber/2)))
        
        /* convert into float */
        let middlePdViewF = CGFloat(middlePdView)
        
        /* convert it to page */
        let middlePage = (middlePdView/Int(width))
        
        dbgRec("recyclePagesCount:\(recyclePagesCount) firstPdViewOriginX:\(firstPdViewOriginX) middlePdView:\(middlePdView) middlePage:\(middlePage)")
        
        /* if we reached a old center (going to left) */
        if middlePdViewF == currentPageOrigin && middlePage > nextPage {
            dbgRec("Old center: currentPageOrigin:\(currentPageOrigin)")
            triggerDesc = middlePage
            triggerAsc = triggerDesc - 1
            dbgRec("DESCENDING triggerAsc:\(triggerAsc) triggerDesc:\(triggerDesc)")
        }
        
        /* if we reached the center (going to right) */
        if centerPdView.frame.origin.x == currentPageOrigin && centerPage < nextPage {
            dbgRec("Reached the new center, centerPage:\(centerPage)")
            triggerAsc = Int(centerPdView.frame.origin.x/width)
            triggerDesc = triggerAsc + 1
            dbgRec("ASCENDING triggerAsc:\(triggerAsc) triggerDesc:\(triggerDesc)")
        }
    }
    
    /*
    * Get scroll information for compute the appending actions.
    * In the ascending order, it returns the last page.
    * In the descending order, it returns the first valid ProductView.
    */
    func recGetScrollPointer(side: String) -> Int {
        let subViews = scrollMenu!.subviews
        if side == "ascending" {
            let reverseCollection = subViews.reverse()
            let reverse = Array(reverseCollection)
            for i in 0..<subViews.count {
                /* scrollview uses two hidden subviews for scrolling purpose */
                if reverse[i] is UIImageView {
                    continue
                }
                /* get the last PdView element */
                if let pdView = reverse[i] as? ProductView {
                    let posX = pdView.frame.origin.x/pdView.frame.size.width
                    /* last valid pos in the scroll */
                    return Int(posX)
                }
            }
        } else if side == "descending" {
            for i in 0..<subViews.count {
                /* find the fist pdview */
                if subViews[i] is ProductView {
                    return i
                }
            }
        }
        
        /* invalid side, should not happen */
        return -1
    }
    
    func recReachedLimit(inout newLimit: Int, side: Bool) -> Bool {
        let subviews = vc!.getProductSubViews()
        let width = scrollMenu!.frame.width
        
        /* ascending */
        if side == false {
            let lastVisibleView = subviews[subviews.count - 1]
            let lastVisiblePage = lastVisibleView.frame.origin.x/width
            
            /* limit is the content size */
            let pageLimit = scrollMenuSize - 1
                dbgRec("lastVisiblePage:\(lastVisiblePage) pageLimit:\(pageLimit)")
            /* reached the limit? */
            if Int(lastVisiblePage) == pageLimit {
                dbgRec("....reached the limit!")
                return true
            }
            
            /* check if we can recycle the recycleNumber value */
            let recycleOffset = Int(lastVisiblePage) + recycleNumber
                dbgRec("recycleOffset:\(recycleOffset)")
            if recycleOffset < pageLimit {
                dbgRec("we can go on...")
                newLimit = recycleNumber
                return false
            }
            
            /* if we can't, reduce the value */
            if recycleOffset > pageLimit {
                newLimit = pageLimit - Int(lastVisiblePage)
                dbgRec("we can go, but less than 3 newLimit:\(newLimit)")
                return false
            }
        } else {
            let firstVisibleView = subviews[0]
            let firstVisiblePage = firstVisibleView.frame.origin.x/width
            
            /* check if we can recycle the recycleNumber value */
            let recycleOffset = Int(firstVisiblePage) - recycleNumber
            dbgRec("recycleOffset:\(recycleOffset)")
            if recycleOffset > 0 {
                dbgRec("we can go on...")
                newLimit = recycleNumber
                return false
            }
            
            if recycleOffset < 0 {
                /* decrease the first page number */
                newLimit = Int(firstVisiblePage)
                dbgRec("we can go, but less than 3 newLimit:\(newLimit)")
                return false
            }
        }
        
        /* we can still recycle */
        dbgRec("still recycle...")
        newLimit = recycleNumber
        return false
    }
    
    /* Recycle 'number' of pages */
    func recRecyclePages(side: String, number: Int) {
        if side == "ascending" {
            for _ in 0..<number {
                /* always the first one */
                let pdView = visiblePages.removeAtIndex(0)
                
                pdView.removeFromSuperview()
                recycledPages.append(pdView)
            }
        } else if side == "descending" {
            /* always be the first, so reverse it */
            for _ in 0..<number {
                /* uses the last one */
                let pdView = visiblePages.removeAtIndex(visiblePages.count - 1)
                
                pdView.removeFromSuperview()
                recycledPages.append(pdView)
                
                /* descending is tricky, need to order it */
                recycledPages.sortInPlace({ $0.frame.origin.x < $1.frame.origin.x})
            }
        }
    }
    
    /* Use a 'number' of recycle pages to increase/decrease the scrollview */
    func recDequeueRecyclePages(side: String, number: Int) {
        if side == "ascending" {
            for _ in 0..<number {
                /* recycle the first one */
                let pdView0 = recycledPages.removeAtIndex(0)
                
                /* get pos and turn into cgfloat */
                let offset = recGetScrollPointer(side) + 1
                let i = CGFloat(offset)
                
                /* update the view position and add to subview */
                pdView0.frame.origin.x = i*pdView0.frame.size.width
                scrollMenu!.addSubview(pdView0)
                
                /* offset for ascendig order uses indexes from '0' to 'n - 1' */
                let newWidth = offset + 1
                scrollMenu!.contentSize = CGSize(width: newWidth *
                    Int(scrollMenu!.bounds.width) , height: 0)
                
                /* update visible pages */
                visiblePages.append(pdView0)
                
                /* flush info */
                vc!.flushProductView(pdView0, transientImg: true)
            }
        } else if side == "descending" {
            for _ in 0..<number {
                /* recycle the first one */
                let pdView0 = recycledPages.removeAtIndex(0)
                
                /* get first pdview, we will insert before it */
                let firstView = recGetScrollPointer(side)
                let firstPdView = scrollMenu!.subviews[firstView] as! ProductView
                
                /* get pos and turn into cgfloat */
                let offset = Int(firstPdView.frame.origin.x) - Int(scrollMenu!.bounds.width)
                let i = CGFloat(offset)
                
                /* update the view position and add to subview */
                pdView0.frame.origin.x = i
                scrollMenu!.insertSubview(pdView0, belowSubview: firstPdView)
                
                /* discount element since we are reducing the width */
                let newWidth = Int(scrollMenu!.contentSize.width) - Int(scrollMenu!.bounds.width)
                scrollMenu!.contentSize = CGSize(width: newWidth , height: 0)
                
                /* update visible pages */
                visiblePages.append(pdView0)
                
                /* flush info */
                vc!.flushProductView(pdView0, transientImg: true)
                
                /* descending is tricky, need to order it */
                visiblePages.sortInPlace({ $0.frame.origin.x < $1.frame.origin.x})
            }
        }
    }
    
    func recDump() {
        /* Visible pages */
        for i in 0..<visiblePages.count {
            let pdView = visiblePages[i]
            dbgRec("VisiblePages> pdViews[\(i)] name:\(pdView.getProduct().name) pdView.frame.origin.x = \(pdView.frame.origin.x) pdView:\(pdView)")
        }
        /* Recycled pages */
        for i in 0..<recycledPages.count {
            let pdView = recycledPages[i]
            dbgRec("RecyclePages> pdViews[\(i)] name:\(pdView.getProduct().name) pdView.frame.origin.x = \(pdView.frame.origin.x) pdView:\(pdView)")
        }
        /* ProductViews */
        for i in 0..<scrollMenu!.subviews.count {
            if let pdView = scrollMenu!.subviews[i] as? ProductView {
                dbgRec("sub> pdView name = \(pdView.getProduct().name) pdView.frame.origin.x = \(pdView.frame.origin.x) page:\(pdView.frame.origin.x/scrollMenu!.frame.width)")
            }
        }
        /* Pointers */
        dbgRec("triggerAsc:\(triggerAsc) triggerDesc:\(triggerDesc)")
        dbgRec("scrollView.contentSize = \(scrollMenu!.contentSize)")
    }
}

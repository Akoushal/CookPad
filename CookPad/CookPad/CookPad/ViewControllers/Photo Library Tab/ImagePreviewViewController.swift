//
//  ImagePreviewViewController.swift
//  CookPad
//
//  Created by Koushal, KumarAjitesh on 2018/11/05.
//  Copyright © 2018 Koushal, KumarAjitesh. All rights reserved.
//

import UIKit

class ImagePreviewViewController: UIViewController {

    var collectionView: UICollectionView!
    var imgArray = [UIImage]()
    var passedContentOffset = IndexPath()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImagePreviewFullViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.isPagingEnabled = true
        view.addSubview(collectionView)
        
        collectionView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.RawValue(UInt8(UIView.AutoresizingMask.flexibleWidth.rawValue) | UInt8(UIView.AutoresizingMask.flexibleHeight.rawValue)))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flowLayout.itemSize = collectionView.frame.size
        flowLayout.invalidateLayout()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidLayoutSubviews() {
        collectionView.scrollToItem(at: passedContentOffset, at: .left, animated: false)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let offset = collectionView.contentOffset
        let width = collectionView.bounds.size.width
        
        let index = round(offset.x / width)
        let newOffset = CGPoint(x: index * size.width, y: offset.y)
        
        collectionView.setContentOffset(newOffset, animated: false)
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionView.reloadData()
            self.collectionView.setContentOffset(newOffset, animated: false)
        }, completion: nil)
    }

}

extension ImagePreviewViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ImagePreviewFullViewCell
        cell.imgView.image = imgArray[indexPath.item]
        return cell
    }
}

extension ImagePreviewViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
}

class ImagePreviewFullViewCell: UICollectionViewCell, UIScrollViewDelegate {
    lazy var scrollImg: UIScrollView = {
        let scroll = UIScrollView()
        scroll.delegate = self
        scroll.alwaysBounceVertical = false
        scroll.alwaysBounceHorizontal = false
        scroll.showsVerticalScrollIndicator = true
        scroll.flashScrollIndicators()
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 4
        return scroll
    }()
    
    lazy var imgView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let doubleTapGest = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView(recognizer:)))
        doubleTapGest.numberOfTapsRequired = 2
        scrollImg.addGestureRecognizer(doubleTapGest)
        
        addSubview(scrollImg)
        scrollImg.addSubview(imgView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollImg.frame = self.bounds
        imgView.frame = self.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        scrollImg.setZoomScale(1, animated: true)
    }
    
    //MARK: - Private Methods
    @objc func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if scrollImg.zoomScale == 1 {
            scrollImg.zoom(to: zoomRectForScale(scale: scrollImg.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollImg.setZoomScale(1, animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imgView.frame.size.height/scale
        zoomRect.size.width = imgView.frame.size.width/scale
        let newCenter = imgView.convert(center, from: scrollImg)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width/2)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height/2)
        return zoomRect
    }
    
    //MARK: - UIScrollView Delegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imgView
    }
}

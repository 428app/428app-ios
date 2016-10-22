import Foundation
import UIKit

extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        _ = _addAndGetConstraintsWithFormat(format, views: views)
    }
    
    func addAndGetConstraintsWithFormat(_ format: String, views: UIView...) -> [NSLayoutConstraint] {
        return _addAndGetConstraintsWithFormat(format, views: views)
    }
    
    fileprivate func _addAndGetConstraintsWithFormat(_ format: String, views: [UIView]) -> [NSLayoutConstraint] {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        let constraints_ = NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary)
        addConstraints(constraints_)
        return constraints_
    }
}


class ViewController: UIViewController,UIScrollViewDelegate {
    
    
    
    fileprivate let scrollView: UIScrollView = {
        let frame = UIScreen.main.bounds
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width - 40, height: 500))
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        return scrollView
    }()
    
    fileprivate lazy var pageControl: UIPageControl = {
        let control = UIPageControl(frame: CGRect(x: 50, y: 300, width: 200, height: 50))
        control.numberOfPages = self.sliderViews.count
        control.currentPage = 0
        control.tintColor = UIColor.lightGray
        control.pageIndicatorTintColor = UIColor.lightGray
        control.currentPageIndicatorTintColor = UIColor.darkGray
        return control
    }()
    
    var sliderViews: [UIColor] = [UIColor.red, UIColor.blue]
    var frame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        setupViews()
    }
    
    func setupViews() {
        view.addSubview(pageControl)
        view.addSubview(scrollView)
        
        for index in 0..<2 {
            frame.origin.x = self.scrollView.frame.size.width * CGFloat(index)
            frame.size = self.scrollView.frame.size
            let subView = UIImageView(frame: frame)
            subView.image = #imageLiteral(resourceName: "LoginSlider1")
            subView.contentMode = .scaleAspectFit
            
            subView.backgroundColor = sliderViews[index]
            self.scrollView .addSubview(subView)
        }
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width * CGFloat(sliderViews.count), height: self.scrollView.frame.size.height)
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: pageControl)
        view.addConstraintsWithFormat("H:|-20-[v0]-20-|", views: scrollView)
        view.addConstraintsWithFormat("V:|-60-[v0(\(self.scrollView.contentSize.height))]-10-[v1]", views: scrollView, pageControl)
    }
    
    
    func configurePageControl() {
        // The total number of pages that are available is based on how many available colors we have.
        self.pageControl.numberOfPages = sliderViews.count
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.lightGray
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.darkGray
        self.view.addSubview(pageControl)
    }
    
    // MARK : TO CHANGE WHILE CLICKING ON PAGE CONTROL
    
    func changePage(sender: AnyObject) -> () {
        let x = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
    
    // Delegate function that changes pageControl when scrollView scrolls
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
}

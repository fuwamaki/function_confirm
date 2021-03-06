//
//  ScreenTransitionViewController.swift
//  FunctionConfirm
//
//  Created by y-maki on 2018/06/25.
//  Copyright © 2018年 牧宥作. All rights reserved.
//

import UIKit

class ScreenTransitionViewController: UIViewController {

    @IBOutlet weak var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // MEMO: 3DTouch対応端末かどうか判定して、Peek&Popを有効化
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            let interaction = UIContextMenuInteraction(delegate: self)
            self.view.addInteraction(interaction)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func nextTouchUpInside(_ sender: Any) {
        transitionToSecondViewController()
    }

    func transitionToSecondViewController() {
        self.performSegue(withIdentifier: "toDisplayViewController", sender: nil)
    }
}

extension ScreenTransitionViewController: UIViewControllerPreviewingDelegate {

    // peek action
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // MEMO: 押下している範囲がボタン内かどうか判定
        let point: CGPoint = nextButton.convert(location, from: self.view)
        guard point.x > 0, point.x < nextButton.bounds.width, point.y > 0, point.y < nextButton.bounds.height else {
            return nil
        }

        let storyBoard = UIStoryboard(name: "ScreenTransition", bundle: nil)
        let secondViewController = storyBoard.instantiateViewController(withIdentifier: "DisplayViewController")
        return secondViewController
    }

    // pop action
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        transitionToSecondViewController()
    }
}

extension ScreenTransitionViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
}

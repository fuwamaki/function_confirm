//
//  SemiModalTestViewController.swift
//  FunctionConfirm
//
//  Created by yusaku maki on 2020/04/03.
//  Copyright © 2020 牧宥作. All rights reserved.
//

import UIKit

final class SemiModalTestViewController: UIViewController {

    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.registerForCell(SemiModalTestTableCell.self)
        }
    }

    private var interactor = OverCurrentTransitioningInteractor()
    private var tableViewContentOffsetY: CGFloat = 0.0
    private var array: [String] = ["1", "2", "3"]

    static func make() -> UIViewController {
        let storyBoard = UIStoryboard(name: "SemiModalTest", bundle: nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "SemiModalTestViewController")
        return viewController
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        tableView.tableFooterView = UIView()
        transitioningDelegate = self
        interactor.startHandler = { [weak self] in
            /// bounces: ScrollViewがコンテンツの端を越えて跳ね返る(bounce)か、また戻るか
            self?.tableView.bounces = false
        }
        interactor.resetHandler = { [weak self] in
            self?.tableView.bounces = true
        }
        /// headerViewの上部を角丸に
        headerView.layer.cornerRadius = 8.0
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        /// handle
        let headerGesture = UIPanGestureRecognizer(target: self, action: #selector(headerDidScroll(_:)))
        headerView.addGestureRecognizer(headerGesture)
        /// handle tap backgroundView
        let gesture = UITapGestureRecognizer(target: self, action: #selector(backgroundDidTap))
        backgroundView.addGestureRecognizer(gesture)
        /// handle swipe tableView
        let tableViewGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTableViewSwipe(_:)))
        tableViewGesture.delegate = self
        tableView.addGestureRecognizer(tableViewGesture)
    }

    @objc private func headerDidScroll(_ sender: UIPanGestureRecognizer) {
        /// ヘッダービューをスワイプした場合の処理
        /// コールされたと同時にインタラクション開始する。
        interactor.updateStateShouldStartIfNeeded()
        handleTransitionGesture(sender)
    }

    @objc private func backgroundDidTap() {
        dismiss(animated: true, completion: nil)
    }

    /// TableViewをSwipeした場合の処理
    @objc private func handleTableViewSwipe(_ sender: UIPanGestureRecognizer) {
        /// TableViewのScrollがTop位置の場合、interactorの状態を更新
        if tableViewContentOffsetY <= 0 {
            interactor.updateStateShouldStartIfNeeded()
        }
        /// インタラクション開始位置と、テーブルビュースクロール開始位置が異なるため、インタラクション開始時のY位置を取得している
        interactor.setStartInteractionTranslationY(sender.translation(in: view).y)
        handleTransitionGesture(sender)
    }

    private func handleTransitionGesture(_ sender: UIPanGestureRecognizer) {
        ///　TableViewからPanGestureを取得する場合、dismiss開始をsender.state.beganで判断できないため、Interactor.stateで判定している
        switch interactor.state {
        case .shouldStart:
            interactor.state = .hasStarted
            dismiss(animated: true, completion: nil)
        case .hasStarted, .shouldFinish:
            break
        case .none:
            return
        }

        /// セミモーダルが画面の何割移動したかを計算
        let translation = sender.translation(in: view)
        let verticalMovement = (translation.y - interactor.startInteractionTranslationY) / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)

        /// PanGesture.stateごとに、インタラクションの更新、終了、キャンセルを制御
        switch sender.state {
        case .changed:
            /// スクロール量がしきい値を超えたか？　もしくは　スクロール速度がしきい値を超えたか？
            if progress > 0.3 || sender.velocity(in: view).y > 1200 {
                interactor.state =  .shouldFinish
            } else {
                interactor.state =  .hasStarted
            }
            interactor.update(progress)
        case .cancelled:
            interactor.cancel()
            interactor.reset()
        case .ended:
            switch interactor.state {
            case .shouldFinish:
                interactor.finish()
            default:
                interactor.cancel()
            }
            interactor.reset()
        default:
            break
        }
    }
}

// MARK: UITableViewDelegate
extension SemiModalTestViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        tableViewContentOffsetY = scrollView.contentOffset.y
    }
}

// MARK: UITableViewDataSource
extension SemiModalTestViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCellForIndexPath(indexPath) as SemiModalTestTableCell
        cell.render(text: array[indexPath.row])
        return cell
    }
}

// MARK: UIGestureRecognizerDelegate
extension SemiModalTestViewController: UIGestureRecognizerDelegate {
    /// 2つ以上のgesture認識を可能にするかどうか
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: UIViewControllerTransitioningDelegate
extension SemiModalTestViewController: UIViewControllerTransitioningDelegate {
    /// SemiModalTestViewへの遷移アニメーションを定義
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SemiModalPresentationController(presentedViewController: presented, presenting: presenting)
    }

    /// SemiModalTestViewを閉じるアニメーションを定義
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SemiModalDismissAnimationController()
    }

    /// SemiModalTestViewを閉じる際に使用するinteractive objectを定義
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        /// インタラクション開始している場合だけinteractorを返す
        switch interactor.state {
        case .hasStarted, .shouldFinish:
            return interactor
        default:
            return nil
        }
    }
}

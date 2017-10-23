//
//  MainTableVC.swift
//  Offtube
//
//  Created by Dirk Gerretz on 05/12/2016.
//  Copyright © 2016 [code2 app];. All rights reserved.
//

import UIKit

protocol MainViewControllerProtocol: class {
    func requestVideo(url: String)
    func reloadVideo(index: Int)
}

class MainViewController: UITableViewController {

    // MARK: - Properties
    var model = MainViewModel()
    @IBOutlet weak var searchBar: UISearchBar!

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // The viewModel has already been initialized as the Datasoure via the Stroryboard
        tableView.dataSource = model
        tableView.delegate = self
        model.viewController = self
        clearsSelectionOnViewWillAppear = true
        setupNavBarItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
	
	func setupNavBarItems(){
		navigationItem.rightBarButtonItem = editButtonItem
		navigationItem.rightBarButtonItem?.tintColor = .white
		navigationController?.navigationBar.barTintColor = UIColor(red: 0.87, green: 0.18, blue: 0.19, alpha: 1.00)
		navigationController?.navigationBar.isTranslucent = false
		navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
	}
	
    // MARK: Actions
    @IBAction func deleteAllTapped(_: UIBarButtonItem) {
        model.deleteAllVideos()
    }

    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "toVideoPlayer" {
            let cell = sender as? VideoCell
            let row = (tableView.indexPath(for: cell!))?.row

            let video = model.videos?[row!]

            let playerView = segue.destination as? VideoViewController
            playerView?.video = video
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "toVideoPlayer" {
            let cell = sender as? VideoCell
            let row = (tableView.indexPath(for: cell!))?.row

            let video = model.videos?[row!]
            if !(VideoManager.fileExists(url: URL(string: (video?.fileLocation)!)!)) {
                let indexPAth = IndexPath(row: row!, section: 0)
                tableView.deselectRow(at: indexPAth, animated: true)
                return false
            }
        }
        return true
    }

    // MARK: Misc.
    static func displayNetworkIndicator(_ on: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = on
        }
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        model.reloadVideo(index: indexPath.row)
    }
}

extension MainViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let url = searchBar.text {
            model.requestVideo(url: url)
        }
    }
}

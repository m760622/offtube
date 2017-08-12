//
//  VideoViewController.swift
//  Offtube
//
//  Created by Dirk Gerretz on 30.06.17.
//  Copyright © 2017 [code2 app];. All rights reserved.
//

// Since the sole purpose of this controller is to play back the
// video that was downloaded, no ViewModel will be created.

import UIKit
import AVKit
import AVFoundation

class VideoViewController: AVPlayerViewController {

    // MARK: Properties
    var video: Video?

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // make sure audio is played even when device is in silent mode
        do {
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playVideo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard video != nil else {
            return
        }

        guard player != nil else {
            return
        }

        video!.timePlayed = (player?.currentItem?.currentTime().seconds)!
        video!.timeRemaining = calculateTimeRemaining(item: (player?.currentItem)!)
        saveContext()
        player = nil
    }

    private func playVideo() {

        guard let videoUrl = video?.fileLocation else {
            print("*** Video url is nil")
            return
        }

        player = AVPlayer(url: URL(string: videoUrl)!)

        // play remainder of video only if more than 5sec are left to be played
        if Int((video?.timeRemaining)!) > 5 {
            let startTime = CMTime(seconds: (video?.timePlayed)!, preferredTimescale: CMTimeScale(kCMTimeMaxTimescale))
            player?.seek(to: startTime)
        }

        player?.play()
    }

    func calculateTimeRemaining(item: AVPlayerItem) -> Double {
        return (item.duration.seconds) - (item.currentTime().seconds)
    }

    func saveContext() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.saveContext()
    }
}

//
//  ViewController.swift
//  N42WebView
//
//  Created by ChangHoon Jung on 12/17/2015.
//  Copyright (c) 2015 ChangHoon Jung. All rights reserved.
//

import UIKit
import N42WebView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func touchWebViewButton(sender: AnyObject) {
        let vc = N42WebViewController(url: "http://naver.com")
        vc.navTitle = "N42 타이틀"
        vc.toolbarStyle = UIBarStyle.Default
        vc.toolbarTintColor = UIColor.orangeColor()
        vc.actionUrl = NSURL(string: "http://daum.net")
        vc.progressViewTintColor = UIColor.redColor()
        
        navigationController?.pushViewController(vc, animated: true)
    }
}


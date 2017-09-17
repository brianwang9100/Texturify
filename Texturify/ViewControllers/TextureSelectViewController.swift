//
//  TextureSelectViewController.swift
//  Texturify
//
//  Created by Brian Wang on 9/17/17.
//  Copyright © 2017 BW. All rights reserved.
//

import UIKit

class TextureSelectViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var textures:[String]!
    
    var callback:((Int) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension TextureSelectViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textures.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextureCell", for: indexPath) as! TextureCell
        let index = indexPath.row
        let name = textures[index]
        cell.reset()
        DispatchQueue.main.async {
            let image = UIImage(named: "./art.scnassets/\(name)/\(name)-albedo.png")!
            UIView.animate(withDuration: 1.0, animations: {
                cell.backgroundImageView.image = image
                cell.squareImageView.image = image
            })
        }
        cell.textureLabel.text = name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        callback(indexPath.row)
        self.navigationController?.popViewController(animated: true)
    }
}

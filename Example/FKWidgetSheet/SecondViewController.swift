/*
 * Apache License
 * Version 2.0, January 2004
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
 *
 * Copyright (c) 2017 Flipkart Internet Pvt. Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of the
 * License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */


import UIKit
import ContentSheet

class SecondViewController: UIViewController {

    @IBOutlet @objc public weak var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.table.register(UITableViewCell.self, forCellReuseIdentifier: "id")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.title = String(arc4random()%100)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    @objc override open func collapsedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return UIScreen.main.bounds.height*0.5
    }
    
    @objc override open func expandedHeight(containedIn contentSheet: ContentSheet) -> CGFloat {
        return UIScreen.main.bounds.height
    }
    

    override func scrollViewToObserve(containedIn contentSheet: ContentSheet) -> UIScrollView? {
        return table
    }
}



extension SecondViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "id")
        
        if self.contentSheet() != nil {
            
            if self.navigationController != nil {
                switch indexPath.row%4 {
                case 0:
                    cell?.textLabel?.text = "Dismiss"
                case 1:
                    cell?.textLabel?.text = "Present Next"
                case 2:
                    cell?.textLabel?.text = "Present NavigationController Next"
                default:
                    cell?.textLabel?.text = "Push ViewController"
                    break
                }
            } else {
                switch indexPath.row%3 {
                case 0:
                    cell?.textLabel?.text = "Dismiss"
                case 1:
                    cell?.textLabel?.text = "Present Next"
                case 2:
                    cell?.textLabel?.text = "Present NavigationController Next"
                default:
                    break
                }
            }
        } else {
            if indexPath.row%2 == 0 {
                cell?.textLabel?.text = "Present"
            } else {
                cell?.textLabel?.text = "Present NavigationController"
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.contentSheet() != nil {
            
            if self.navigationController != nil {
                switch indexPath.row%4 {
                case 0:
                    self.dismissContentSheet(animated: true)
                case 1:
                    let secondVC = SecondViewController(nibName: nil, bundle: nil)
                    self.present(inContentSheet: secondVC, animated: true)
                case 2:
                    let secondVC = SecondViewController(nibName: nil, bundle: nil)
                    let navcon = UINavigationController(rootViewController: secondVC)
                    self.present(inContentSheet: navcon, animated: true)
                default:
                    let secondVC = SecondViewController(nibName: nil, bundle: nil)
                    self.navigationController?.pushViewController(secondVC, animated: true)
                    break
                }
            } else {
                switch indexPath.row%3 {
                case 0:
                    self.dismissContentSheet(animated: true)
                case 1:
                    let secondVC = SecondViewController(nibName: nil, bundle: nil)
                    self.present(inContentSheet: secondVC, animated: true)
                case 2:
                    let secondVC = SecondViewController(nibName: nil, bundle: nil)
                    let navcon = UINavigationController(rootViewController: secondVC)
                    self.present(inContentSheet: navcon, animated: true)
                default:
                    break
                }
            }
        } else {
            if indexPath.row%2 == 0 {
                let secondVC = SecondViewController(nibName: nil, bundle: nil)
                self.present(inContentSheet: secondVC, animated: true)
            } else {
                let secondVC = SecondViewController(nibName: nil, bundle: nil)
                let navcon = UINavigationController(rootViewController: secondVC)
                self.present(inContentSheet: navcon, animated: true)
            }
        }
    }
    
    
    override func preferredStatusBarStyle(contentSheet: ContentSheet) -> UIStatusBarStyle {
        return .lightContent
    }
}



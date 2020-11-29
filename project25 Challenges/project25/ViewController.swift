//
//  ViewController.swift
//  project25
//
//  Created by Anisha Lamichhane on 9/30/20.
//
import MultipeerConnectivity
import UIKit

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate{
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
            print("not Connected: \(peerID.displayName)")
            let ac = UIAlertController(title: "Anisha's Ipad is disconnected", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            
        @unknown default:
            print("Unknown state received : \(peerID.displayName)")
        }
    }
    /*
    Once the data arrives at each peer, the method session(_:didReceive:fromPeer:) will get called with that data, at which point we can create a UIImage from it and add it to our images array. There is one catch: when you receive data it might not be on the main thread, and you never manipulate user interfaces anywhere but the main thread, right? Right.
    
    Here's the final protocol method, to catch data being received in our session:
    */
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            let strData = String(decoding: data, as: UTF8.self)
            if let image = UIImage(data: data){
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            }
        
        
        if strData != "" {
            let ac = UIAlertController(title: "Message", message: strData, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self?.present(ac, animated: true)
        }
        print(#function)
        print(strData)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    //    we use this array to know how many items are there in the collection view
    var images = [UIImage]()
    var message = ""
    
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession : MCSession?
    var mcAdvertisorAssistant : MCAdvertiserAssistant?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Selfie Share"
        let hostButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        let messageButton = UIBarButtonItem(title: "Chat", style: .plain, target: self, action: #selector(sendMessages))
        let namesButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(showNamesOfConnection))
        let photoButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        navigationItem.leftBarButtonItems = [photoButton, messageButton]
        navigationItem.rightBarButtonItems = [hostButton, namesButton]
        
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    @objc func sendMessages() {
        let ac = UIAlertController(title: "Send Messages", message: nil, preferredStyle: .alert)
        ac.addTextField{ (textField) in
            textField.placeholder = "Your Message"
        }
        let send = UIAlertAction(title: "Send", style: .default) { _ in
            guard let text = ac.textFields?[0].text else { return}
            self.message = text
            self.sendTextToPeers(message: text)
        }
        ac.addAction(send)
        ac.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(ac, animated: true)
        
    }
    
    func sendTextToPeers(message: String){
        guard let mcSession = mcSession else { return }
        let data = Data(message.utf8)
        if mcSession.connectedPeers.count > 0 {
            if message != "" {
                do {
                    print(message)
                    try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    let ac = UIAlertController(title: "Send Error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
    }
}
    
    @objc func showNamesOfConnection() {
        guard let mcSession = mcSession else { return }
        let connection = mcSession.connectedPeers.description
        let ac = UIAlertController(title: "connectedPeers", message: connection, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(ac, animated: true)
    }
    
    func startHosting(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        mcAdvertisorAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
        
        mcAdvertisorAssistant?.start()
    }
    
    func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image  = images[indexPath.item] // bring that image from indexpath.item and place it in imageview.image.
        }
        return cell // that cell goes backa and shows inside collection view.
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        images.insert(image, at: 0)
        collectionView.reloadData()
        
        guard let mcSession = mcSession else { return }
        if mcSession.connectedPeers.count > 0 {
            if let imageData = image.pngData() {
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    let ac = UIAlertController(title: "Send Error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    
}


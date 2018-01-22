/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSessionDelegate {
    
    // MARK: Outlets

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var shirtButton: UIButton!
    @IBOutlet weak var buyButton: UIButton!
    
    /*lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()*/

    // MARK: Properties

    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }

    var nodeForContentType = [VirtualContentType: VirtualFaceNode]()
    
    let contentUpdater = VirtualContentUpdater()
    
    var selectedVirtualContent: VirtualContentType = .none {
        didSet {
            // Set the selected content based on the content type.
            contentUpdater.virtualFaceNode = nodeForContentType[selectedVirtualContent]
        }
    }

    @IBAction func buyJersey(_ sender: UIButton) {
        let alert = UIAlertController(title: "Purchase", message: "Would you like to buy for $100?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: nil))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func shareJersey(_ sender: UIButton) {
        let jerseyImage = sceneView.snapshot()
        session.pause()
        let activityItem: [AnyObject] = [jerseyImage as AnyObject]
        let avc = UIActivityViewController(activityItems: activityItem as [AnyObject], applicationActivities: nil)
        avc.completionWithItemsHandler = { (type, completed, items, error) in
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            self.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        self.present(avc, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = contentUpdater
        sceneView.session.delegate = self
        sceneView.autoenablesDefaultLighting = false;
        
        shareButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 16, 16)
        shareButton.layer.cornerRadius = 30.5
        shareButton.layer.shadowColor = UIColor.black.cgColor
        shareButton.layer.shadowOpacity = 0.3
        shareButton.layer.shadowOffset = CGSize.zero
        shareButton.layer.shadowRadius = 10
        
        shirtButton.imageEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12)
        shirtButton.layer.cornerRadius = 30.5
        shirtButton.layer.shadowColor = UIColor.black.cgColor
        shirtButton.layer.shadowOpacity = 0.3
        shirtButton.layer.shadowOffset = CGSize.zero
        shirtButton.layer.shadowRadius = 10
        
        buyButton.imageEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12)
        buyButton.layer.cornerRadius = 30.5
        buyButton.layer.shadowColor = UIColor.black.cgColor
        buyButton.layer.shadowOpacity = 0.3
        buyButton.layer.shadowOffset = CGSize.zero
        buyButton.layer.shadowRadius = 10
        
        createFaceGeometry()

        // Set the initial face content, if any.
        contentUpdater.virtualFaceNode = nodeForContentType[selectedVirtualContent]

        // Hook up status view controller callback(s).
        /*statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }*/
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        resetTracking()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        session.pause()
    }
    
    func createFaceGeometry() {
        let device = sceneView.device!
        let maskGeometry = ARSCNFaceGeometry(device: device)!
        let glassesGeometry = ARSCNFaceGeometry(device: device)!
        
        nodeForContentType = [
            .faceGeometry: BlueJersey(geometry: maskGeometry),
            .overlayModel: RedJersey(geometry: glassesGeometry),
            .blendShapeModel: OldJersey(geometry: glassesGeometry)
        ]
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.flatMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        blurView.isHidden = false
        /*statusViewController.showMessage("""
        SESSION INTERRUPTED
        The session will be reset after the interruption has ended.
        """, autoHide: false)*/
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        blurView.isHidden = true
        
        DispatchQueue.main.async {
            self.resetTracking()
        }
    }
    
    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        //statusViewController.showMessage("STARTING A NEW SESSION")
        
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - Interface Actions

    /// - Tag: restartExperience
    func restartExperience() {
        // Disable Restart button for a while in order to give the session enough time to restart.
        //statusViewController.isRestartExperienceButtonEnabled = false
        /*DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.statusViewController.isRestartExperienceButtonEnabled = true
        }*/

        resetTracking()
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        /*
         Popover segues should not adapt to fullscreen on iPhone, so that
         the AR session's view controller stays visible and active.
        */
        return .none
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
         All segues in this app are popovers even on iPhone. Configure their popover
         origin accordingly.
        */
        guard let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton else { return }
        popoverController.delegate = self
        popoverController.sourceRect = button.bounds

        // Set up the view controller embedded in the popover.
        let contentSelectionController = popoverController.presentedViewController as! ContentSelectionController

        // Set the initially selected virtual content.
        contentSelectionController.selectedVirtualContent = selectedVirtualContent

        // Update our view controller's selected virtual content when the selection changes.
        contentSelectionController.selectionHandler = { [unowned self] newSelectedVirtualContent in
            self.selectedVirtualContent = newSelectedVirtualContent
        }
    }
}

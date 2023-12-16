//
//  MainLoginWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 12/7/23.
//

import Cocoa

class MainLoginWindowController: NSWindowController,NSWindowDelegate {
    var controlsViewController: ControlsViewController?
    var setupDone=false
    @IBOutlet weak var backgroundImageView: NSImageView!
    @IBOutlet weak var loginWindowView: NSView!
    var resolutionObserver:Any?
    var networkChangeObserver:Any?
    var centerView:NSView?
    var mechanism:XCredsMechanismProtocol?

    override func windowDidLoad() {
        TCSLogWithMark()
        super.windowDidLoad()

        window?.canBecomeVisibleWithoutLogin=true
        let screenRect = NSScreen.screens[0].frame
        window?.setFrame(screenRect, display: true, animate: false)
        window?.alphaValue=0.9
    }

    override func awakeFromNib() {
        TCSLogWithMark()
        //awakeFromNib gets called multiple times. guard against that.
        if setupDone == false {
//            updateLoginWindowInfo()
            setupDone=true
            setupLoginWindowAppearance()

//            os_log("Finishing loading loginwindow", log: uiLog, type: .debug)

            // Disabling due to it causing screen resizing during EULA
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self,
                                           selector: #selector(updateWindow),
                                           name: NSApplication.didChangeScreenParametersNotification,
                                           object: nil)
        }

    }
    @objc fileprivate func updateWindow() {
        TCSLogWithMark()
        DispatchQueue.main.async{
            if self.window?.isVisible ?? true {
                let screenRect = NSScreen.screens[0].frame
                let screenWidth = screenRect.width
                let screenHeight = screenRect.height

                self.window?.setFrame(NSMakeRect(0,0 , screenWidth, screenHeight), display: true)

                if let height = self.controlsViewController?.view.frame.size.height {
                    let rect = NSMakeRect(0, 0, screenWidth,height)

                    self.controlsViewController?.view.frame=rect
                }
                self.recenterCenterView()
            }
        }
    }
    func setupLoginWindowAppearance() {

        TCSLogWithMark("setting up window...")

        self.window?.backgroundColor = NSColor.gray
        self.window?.titlebarAppearsTransparent = true

        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true

        let screenRect = NSScreen.screens[0].frame

        self.window?.setFrame(screenRect, display: true, animate: false)
        let rect = NSMakeRect(0, 0, self.window?.contentView?.frame.size.width ?? 100,117)

        self.controlsViewController?.view.frame=rect

        let backgroundImage = DefaultsHelper.backgroundImage()
        TCSLogWithMark()
        if let backgroundImage = backgroundImage {
            backgroundImage.size=screenRect.size
            self.backgroundImageView.image=backgroundImage
            self.backgroundImageView.imageScaling = .scaleProportionallyUpOrDown

            self.backgroundImageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height-100)

        }
        self.window?.level = .normal

        if self.controlsViewController==nil {
            self.controlsViewController = ControlsViewController.initFromPlugin()
        }
        else {
            self.controlsViewController!.view.removeFromSuperview()
        }

        guard let controlsViewController = self.controlsViewController else {
            return
        }
        self.controlsViewController?.delegate=mechanism

        TCSLogWithMark()
        self.window?.contentView?.addSubview(controlsViewController.view)
        if let width = self.window?.frame.size.width {
            let rect2 = NSMakeRect(0, 0, width,controlsViewController.view.frame.size.height)
            controlsViewController.view.frame=rect2

        }
        TCSLogWithMark("create background windows")
        self.createBackground()

        TCSLogWithMark()

    }

    func loginTransition( completion:@escaping ()->Void) {
        DispatchQueue.main.async {


            TCSLogWithMark()
            let screenRect = NSScreen.screens[0].frame
            let progressIndicator=NSProgressIndicator.init(frame: NSMakeRect(screenRect.width/2-16  , 3*screenRect.height/4-16,32, 32))
            progressIndicator.style = .spinning
            progressIndicator.startAnimation(self)
            self.window?.contentView?.addSubview(progressIndicator)

            if let resolutionObserver = self.resolutionObserver {
                NotificationCenter.default.removeObserver(resolutionObserver)
            }
            if let networkChangeObserver = self.networkChangeObserver {
                NotificationCenter.default.removeObserver(networkChangeObserver)
            }

            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 1.0
                context.allowsImplicitAnimation = true
                self.centerView?.animator().alphaValue = 0.0
                let origin = self.controlsViewController?.view.frame.origin
                let size = self.controlsViewController?.view.frame.size

                if let origin = origin, let size = size {
                    self.controlsViewController?.view.animator().setFrameOrigin(NSMakePoint(origin.x, origin.y-(2*size.height)))
                }
            }, completionHandler: {
                self.centerView?.alphaValue = 0.0
                self.controlsViewController?.view.animator().alphaValue=0.0

                self.centerView?.removeFromSuperview()
                self.controlsViewController?.view.removeFromSuperview()
                completion()
            })
        }

    }

    fileprivate func createBackground() {
        let backgroundImage = DefaultsHelper.backgroundImage()
        let screenRect = NSScreen.screens[0].frame
        TCSLogWithMark()
        if let backgroundImage = backgroundImage {
            TCSLogWithMark()
            backgroundImageView.image?.size=screenRect.size
            TCSLogWithMark()

            backgroundImageView.image=backgroundImage
            TCSLogWithMark()

            backgroundImage.size=screenRect.size
            TCSLogWithMark()

            backgroundImageView.imageScaling = .scaleProportionallyUpOrDown
            TCSLogWithMark()
            backgroundImageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height-100)
            TCSLogWithMark()

        }
        TCSLogWithMark()

    }
    func recenterCenterView()  {
        if let contentView = self.window?.contentView, let centerView = self.centerView {
            var x = NSMidX(contentView.frame)
            var y = NSMidY(contentView.frame)

            x = x - centerView.frame.size.width/2
            y = y - centerView.frame.size.height/2
            let lowerLeftCorner = NSPoint(x: x, y: y)

            centerView.setFrameOrigin(lowerLeftCorner)
        }
        if let controlsView = controlsViewController?.view {
            controlsView.removeFromSuperview()
            self.window?.contentView?.addSubview(controlsView)

        }
    }
    func addCenterView(_ centerView:NSView){
        TCSLogWithMark("re-centering")
        if self.centerView != nil {
            self.centerView?.removeFromSuperview()
        }
        self.centerView=centerView
        self.window?.contentView?.addSubview(centerView)
        recenterCenterView()
    }




}

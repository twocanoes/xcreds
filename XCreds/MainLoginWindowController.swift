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
//    var resolutionObserver:Any?
    var networkChangeObserver:Any?
    var centerView:NSView?
    var mechanism:XCredsMechanismProtocol?
    var timer:Timer?
    var windowArray:Array<NSWindow>=[]
    override func windowDidLoad() {
        TCSLogWithMark()
        super.windowDidLoad()
        window?.canBecomeVisibleWithoutLogin=true
        let screenRect = NSScreen.screens[0].frame
        window?.setFrame(screenRect, display: true, animate: false)
        window?.alphaValue=0.95

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { timer in
            //added this because https://github.com/twocanoes/xcreds/issues/272

            if let path = DefaultsOverride.standardOverride.string(forKey: PrefKeys.hideIfPathExists.rawValue), FileManager.default.fileExists(atPath:path ) {

                if self.window?.isVisible==true {
                    TCSLogWithMark("window is visible and hide path has item at it so hiding window")
                    self.window?.orderOut(self)
                }
            }
            else { //
                if self.window?.isVisible==false {
                    TCSLogWithMark("window is not visible and default does exist so moving to front")

                    self.window?.makeKeyAndOrderFront(self)
                }
                self.window?.forceToFrontAndFocus(self)
            }
        })
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            if self.window?.isVisible ?? true {
                let screenRect = NSScreen.screens[0].frame
                let screenWidth = screenRect.width
                let screenHeight = screenRect.height

                TCSLogWithMark("screenRect: \(screenRect)")
                self.window?.setFrame(NSMakeRect(0,0 , screenWidth, screenHeight), display: true)

                if let height = self.controlsViewController?.view.frame.size.height {
                    let rect = NSMakeRect(0, 0, screenWidth,height)

                    self.controlsViewController?.view.frame=rect
                }
                self.recenterCenterView()
                self.updateBackground()

            }
        }
    }
    func setupLoginWindowAppearance() {

        TCSLogWithMark("setting up window...")

        self.window?.backgroundColor = NSColor.black
        self.window?.titlebarAppearsTransparent = true

        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true
        self.window?.level = .normal

        let screenRect = NSScreen.screens[0].frame

        self.window?.setFrame(screenRect, display: true, animate: false)
        let rect = NSMakeRect(0, 0, self.window?.contentView?.frame.size.width ?? 100,117)

        self.controlsViewController?.view.frame=rect

        TCSLogWithMark()

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
        self.updateBackground()

        TCSLogWithMark()
        controlsViewController.showPopoverIfNeeded()
         
    }

    func loginTransition( completion:@escaping ()->Void) {
        DispatchQueue.main.async {


            if let timer = self.timer, timer.isValid==true {
                TCSLogWithMark("invalidating timer")
                timer.invalidate()

            }
            TCSLogWithMark()
            let screenRect = NSScreen.screens[0].frame
            let progressIndicator=NSProgressIndicator.init(frame: NSMakeRect(screenRect.width/2-16  , 3*screenRect.height/4-16,32, 32))
            progressIndicator.style = .spinning
            progressIndicator.startAnimation(self)
            self.window?.contentView?.addSubview(progressIndicator)

            NotificationCenter.default.removeObserver(self)

            if let networkChangeObserver = self.networkChangeObserver {
                NotificationCenter.default.removeObserver(networkChangeObserver)
            }
            self.controlsViewController?.allowPopoverClose=true
            if self.controlsViewController?.systemInfoPopover.isShown==true {
                self.controlsViewController?.systemInfoPopover.performClose(self)

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
//                self.window?.orderOut(self)
                TCSLogWithMark("completion")
                completion()
            })
        }

    }

    fileprivate func updateBackground() {
        TCSLogWithMark()
        if windowArray.count>1{
            for i in 1..<windowArray.count{

                windowArray[i].contentView?.removeFromSuperview()

            }
        }
        windowArray.removeAll()
        if let window = window {
            windowArray.append(window)
        }

        var i=0
        var currWindow:NSWindow
        for screen in NSScreen.screens{
            if i>0{
                let newWindow = NSWindow(contentRect: .init(origin: .zero,
                                                            size: .init(width: screen.frame.width,
                                                                        height: screen.frame.height)),
                                         styleMask: [],
                                         backing: .buffered,
                                         defer: false,
                                         screen: screen)
                newWindow.backgroundColor = NSColor.black
                newWindow.titlebarAppearsTransparent = true

                newWindow.isMovable = false
                newWindow.canBecomeVisibleWithoutLogin = true
                newWindow.level = .normal

                windowArray.append(newWindow)
            }

            currWindow = windowArray[i]
            let backgroundImage = DefaultsHelper.backgroundImage()

            let screenRect = screen.frame
            var newHeight = screenRect.height
            var newWidth = screenRect.width

            if let backgroundImage = backgroundImage{
                if i==0{


                    if UserDefaults.standard.bool(forKey: PrefKeys.shouldLoginWindowBackgroundImageFillScreen.rawValue) == false {

                        let ratio = backgroundImage.size.width/backgroundImage.size.height
                        newHeight = screenRect.size.height
                        newWidth = screenRect.size.height * ratio

                        if newWidth > screenRect.size.width {
                            newWidth = screenRect.size.width
                            newHeight = screenRect.size.width / ratio
                        }

                    }
                    else {

                        backgroundImage.size.height = newHeight
                        backgroundImage.size.width = newWidth
                        
                        backgroundImageView.imageScaling = .scaleAxesIndependently

                        backgroundImageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height-100)

                    }
                    //main screen
                    backgroundImageView.imageScaling = .scaleAxesIndependently
                    backgroundImage.size.height = newHeight
                    backgroundImage.size.width = newWidth

                    backgroundImageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, newWidth, newHeight-100)
                    backgroundImageView.image=backgroundImage
                    backgroundImageView.alphaValue = CGFloat(DefaultsOverride.standardOverride.float(forKey: PrefKeys.loginWindowBackgroundImageAlpha.rawValue))

                }
                else {
                    let newBackgroundImageView = NSImageView()

                    if let secondardBackgroundImage = DefaultsHelper.secondaryBackgroundImage(){


                        if UserDefaults.standard.bool(forKey: PrefKeys.shouldLoginWindowSecondaryMonitorsBackgroundImageFillScreen.rawValue) == false {
                            let ratio = secondardBackgroundImage.size.width/secondardBackgroundImage.size.height
                            newHeight = screenRect.size.height
                            newWidth = screenRect.size.height * ratio

                            if newWidth > screenRect.size.width {
                                newWidth = screenRect.size.width
                                newHeight = screenRect.size.width / ratio
                            }

                        }
                        else {
                            secondardBackgroundImage.size.height = newHeight
                            secondardBackgroundImage.size.width = newWidth

                            newBackgroundImageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height-100)

                        }
                        newBackgroundImageView.imageScaling = .scaleAxesIndependently
                        secondardBackgroundImage.size.height = newHeight
                        secondardBackgroundImage.size.width = newWidth

                        //secondary screens
                        newBackgroundImageView.image=secondardBackgroundImage
                        newBackgroundImageView.alphaValue = CGFloat(DefaultsOverride.standardOverride.float(forKey: PrefKeys.loginWindowSecondaryMonitorsBackgroundAlpha.rawValue))

                        newBackgroundImageView.imageScaling = .scaleAxesIndependently
                        newBackgroundImageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height)
                        currWindow.contentView=newBackgroundImageView
                        currWindow.makeKeyAndOrderFront(self)

                    }
                }

            }
            i += 1
        }

    }
    func recenterCenterView()  {
         TCSLogWithMark()
        if let contentView = self.window?.contentView, let centerView = self.centerView {
            TCSLogWithMark()

            var x = NSMidX(contentView.frame)
            var y = NSMidY(contentView.frame)
            TCSLogWithMark("x:\(x) y:\(y) center width: \(centerView.frame.size.width), centerview height: \(centerView.frame.size.height)")
            x = x - centerView.frame.size.width/2
            y = y - centerView.frame.size.height/2
            let lowerLeftCorner = NSPoint(x: x, y: y)

            centerView.setFrameOrigin(lowerLeftCorner)
            TCSLogWithMark("\(x):\(y)")

        }
        else {
            TCSLogWithMark("invalid contentView or center view")
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

//
//  SettingsViewController.swift
//  JapaneseLDSQuad
//
//  Created by Nozomi Okada on 2/15/20.
//  Copyright © 2020 nozokada. All rights reserved.
//

import UIKit

@IBDesignable
class SettingsViewController: UITableViewController {
    
    var delegate: SettingsViewDelegate?
    
    @IBOutlet weak var alternativeFontSwitch: UIButton!
    @IBOutlet weak var alternativeFontLabel: UILabel!
    @IBOutlet weak var nightModeSwitch: UIButton!
    @IBOutlet weak var nightModeLabel: UILabel!
    @IBOutlet weak var dualModeSwitch: UIButton!
    @IBOutlet weak var dualModeSwitchLabel: UILabel!
    @IBOutlet weak var sideBySideModeSwitch: UIButton!
    @IBOutlet weak var sideBySideModeSwitchLabel: UILabel!
    @IBOutlet weak var textSizeStepper: UIStepper!
    @IBOutlet weak var textSizeStepperLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setLabelsText()
//        setTextSizeStepperImages()
        setAlternativeFontSwitchState()
        setNightModeSwitchState()
        setDualModeSwitchState()
        setSideBySideModeSwitchState()
        setTextSizeStepperValue()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "settingsGroupedTableViewLabel".localized
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tableView.backgroundColor = Utilities.shared.getBackgroundColor()
        cell.backgroundColor = Utilities.shared.getCellColor()
        
        let fontColor = Utilities.shared.getTextColor()
        alternativeFontLabel.textColor = fontColor
        nightModeLabel.textColor = fontColor
        dualModeSwitchLabel.textColor = fontColor
        sideBySideModeSwitchLabel.textColor = fontColor
        textSizeStepperLabel.textColor = fontColor
    }
    
    fileprivate func setLabelsText() {
        alternativeFontLabel.text = "settingMinchoFontLabel".localized
        nightModeLabel.text = "settingNightModeLabel".localized
        dualModeSwitchLabel.text = "settingDualSwitchLabel".localized
        sideBySideModeSwitchLabel.text = "settingSideBySideSwitchLabel".localized
        textSizeStepperLabel.text = "settingfontSizeStepperLabel".localized
    }
    
    fileprivate func setAlternativeFontSwitchState() {
        let state = Utilities.shared.alternativeFontEnabled
        alternativeFontSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOn") : #imageLiteral(resourceName: "ToggleOff"), for: .normal)
    }
    
    fileprivate func setNightModeSwitchState() {
        let state = Utilities.shared.nightModeEnabled
        nightModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOn") : #imageLiteral(resourceName: "ToggleOff"), for: .normal)
    }
    
    fileprivate func setDualModeSwitchState() {
        let state = Utilities.shared.dualEnabled
        dualModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOn") : #imageLiteral(resourceName: "ToggleOff"), for: .normal)
    }
    
    
    fileprivate func setTextSizeStepperValue() {
        textSizeStepper.value = Utilities.shared.fontSizeMultiplier
    }
    
    fileprivate func setSideBySideModeSwitchState() {
        let currState = Utilities.shared.sideBySideEnabled
        sideBySideModeSwitch.setImage(currState ? #imageLiteral(resourceName: "ToggleOn") : #imageLiteral(resourceName: "ToggleOff"), for: .normal)
    }
    
    fileprivate func setTextSizeStepperImages() {
        textSizeStepper.setIncrementImage(#imageLiteral(resourceName: "TextSizePlus"), for: .normal)
        textSizeStepper.setIncrementImage(#imageLiteral(resourceName: "TextSizeActivePlus"), for: .highlighted)
        textSizeStepper.setIncrementImage(#imageLiteral(resourceName: "TextSizeDisabledPlus"), for: .disabled)
        textSizeStepper.setDecrementImage(#imageLiteral(resourceName: "TextSizeMinus"), for: .normal)
        textSizeStepper.setDecrementImage(#imageLiteral(resourceName: "TextSizeActiveMinus"), for: .highlighted)
        textSizeStepper.setDecrementImage(#imageLiteral(resourceName: "TextSizeDisabledMinus"), for: .disabled)
        textSizeStepper.setDividerImage(#imageLiteral(resourceName: "TextSizeDivider"), forLeftSegmentState: .normal, rightSegmentState: .normal)
        textSizeStepper.setDividerImage(#imageLiteral(resourceName: "TextSizeDivider"), forLeftSegmentState: .highlighted, rightSegmentState: .normal)
        textSizeStepper.setDividerImage(#imageLiteral(resourceName: "TextSizeDivider"), forLeftSegmentState: .normal, rightSegmentState: .highlighted)
    }
    
    @IBAction func alternativeFontSwitchToggled(_ sender: Any) {
        let state = Utilities.shared.alternativeFontEnabled
        UserDefaults.standard.set(!state, forKey: Constants.Config.font)
        alternativeFontSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOff") : #imageLiteral(resourceName: "ToggleOn") , for: .normal)
        delegate?.reload()
    }
    
    @IBAction func nightModeSwitchToggled(_ sender: Any) {
        let state = Utilities.shared.nightModeEnabled
        UserDefaults.standard.set(!state, forKey: Constants.Config.night)
        nightModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOff") : #imageLiteral(resourceName: "ToggleOn") , for: .normal)
        delegate?.reload()
        tableView.reloadData()
    }
    
    @IBAction func dualModeSwitchToggled(_ sender: Any) {
        let state = Utilities.shared.dualEnabled
        UserDefaults.standard.set(!state, forKey: Constants.Config.dual)
        dualModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOff") : #imageLiteral(resourceName: "ToggleOn") , for: .normal)
        delegate?.reload()
    }
    
    @IBAction func sideBySideModeSwitchToggled(_ sender: Any) {
        if !PurchaseManager.shared.allFeaturesUnlocked {
            presentPuchaseViewController()
            return
        }
        let state = Utilities.shared.sideBySideEnabled
        UserDefaults.standard.set(!state, forKey: Constants.Config.side)
        sideBySideModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOff") : #imageLiteral(resourceName: "ToggleOn") , for: .normal)
        delegate?.reload()
    }
    
    @IBAction func fontSizeStepperTapped(_ sender: Any) {
        UserDefaults.standard.set(textSizeStepper.value, forKey: Constants.Config.size)
        delegate?.reload()
    }
}

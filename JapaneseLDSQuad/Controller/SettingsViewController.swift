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
    
    var delegate: SettingsChangeDelegate?
    
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
        tableView.backgroundColor = AppUtility.shared.getBackgroundColor()
        cell.backgroundColor = AppUtility.shared.getCellColor()
        
        let fontColor = AppUtility.shared.getTextColor()
        alternativeFontLabel.textColor = fontColor
        nightModeLabel.textColor = fontColor
        dualModeSwitchLabel.textColor = fontColor
        sideBySideModeSwitchLabel.textColor = fontColor
        textSizeStepperLabel.textColor = fontColor
    }
    
    func setLabelsText() {
        alternativeFontLabel.text = "settingMinchoFontLabel".localized
        nightModeLabel.text = "settingNightModeLabel".localized
        dualModeSwitchLabel.text = "settingDualSwitchLabel".localized
        sideBySideModeSwitchLabel.text = "settingSideBySideSwitchLabel".localized
        textSizeStepperLabel.text = "settingfontSizeStepperLabel".localized
    }
    
    func setAlternativeFontSwitchState() {
        let state = AppUtility.shared.alternativeFontEnabled
        alternativeFontSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOn") : #imageLiteral(resourceName: "ToggleOff"), for: .normal)
    }
    
    func setNightModeSwitchState() {
        let state = AppUtility.shared.nightModeEnabled
        nightModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOn") : #imageLiteral(resourceName: "ToggleOff"), for: .normal)
    }
    
    func setDualModeSwitchState() {
        let state = AppUtility.shared.dualEnabled
        dualModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOn") : #imageLiteral(resourceName: "ToggleOff"), for: .normal)
    }
    
    
    func setTextSizeStepperValue() {
        textSizeStepper.value = AppUtility.shared.fontSizeRate
    }
    
    func setSideBySideModeSwitchState() {
        if PurchaseManager.shared.isPurchased {
            let currState = AppUtility.shared.sideBySideEnabled
            sideBySideModeSwitch.setImage(currState ? #imageLiteral(resourceName: "ToggleOn") : #imageLiteral(resourceName: "ToggleOff"), for: .normal)
        } else {
            sideBySideModeSwitch.alpha = 0.5
            sideBySideModeSwitch.isEnabled = false
            sideBySideModeSwitchLabel.alpha = 0.5
        }
    }
    
    func setTextSizeStepperImages() {
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
        let state = AppUtility.shared.alternativeFontEnabled
        UserDefaults.standard.set(!state, forKey: Constants.Config.font)
        alternativeFontSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOff") : #imageLiteral(resourceName: "ToggleOn") , for: .normal)
        delegate?.reload()
    }
    
    @IBAction func nightModeSwitchToggled(_ sender: Any) {
        let state = AppUtility.shared.nightModeEnabled
        UserDefaults.standard.set(!state, forKey: Constants.Config.night)
        nightModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOff") : #imageLiteral(resourceName: "ToggleOn") , for: .normal)
        delegate?.reload()
        tableView.reloadData()
    }
    
    @IBAction func dualModeSwitchToggled(_ sender: Any) {
        let state = AppUtility.shared.dualEnabled
        UserDefaults.standard.set(!state, forKey: Constants.Config.dual)
        dualModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOff") : #imageLiteral(resourceName: "ToggleOn") , for: .normal)
        delegate?.reload()
    }
    
    @IBAction func sideBySideModeSwitchToggled(_ sender: Any) {
        let state = AppUtility.shared.sideBySideEnabled
        UserDefaults.standard.set(!state, forKey: Constants.Config.side)
        sideBySideModeSwitch.setImage(state ? #imageLiteral(resourceName: "ToggleOff") : #imageLiteral(resourceName: "ToggleOn") , for: .normal)
        delegate?.reload()
    }
    
    @IBAction func fontSizeStepperTapped(_ sender: Any) {
        UserDefaults.standard.set(textSizeStepper.value, forKey: Constants.Config.size)
        delegate?.reload()
    }
}

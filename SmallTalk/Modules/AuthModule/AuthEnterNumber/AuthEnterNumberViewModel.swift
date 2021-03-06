//
//  AuthEnterNumberViewModel.swift
//  epam_messenger
//
//  Created by Anton Pryakhin on 09.03.2020.
//

import Foundation
import FirebaseAuth

protocol AuthEnterNumberViewModelProtocol {
    func verifyNumber(number: String)
}

struct AuthEnterNumberViewModel: AuthEnterNumberViewModelProtocol {
    let router: RouterProtocol
    let viewController: AuthEnterNumberViewControllerProtocol
    
    func verifyNumber(number: String) {
        PhoneAuthProvider.provider().verifyPhoneNumber(number, uiDelegate: nil) { (verificationId, error) in
            if let error = error {
                self.viewController.showErrorAlert(error.localizedDescription)
                return
            }
            
            guard let verificationId = verificationId else { return }
            
            guard let router = self.router as? AuthRouter else { return }
            router.showAuthEnterCode(verificationId: verificationId, number: number)
        }
    }
    
    init(router: RouterProtocol, viewController: AuthEnterNumberViewControllerProtocol) {
        self.router = router
        self.viewController = viewController
    }
}

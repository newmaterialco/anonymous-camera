////
////  InAppManager.swift
////  anonymous-camera
////
////  Created by Alisdair Mills on 23/03/2020.
////  Copyright © 2020 Aaron Abentheuer. All rights reserved.
////
//
//import Foundation
//import StoreKit
//
//class InAppManager: NSObject {
//
//    private static let PRO_ID = "Anon_Pro"
//    private var productsRequest: SKProductsRequest?
//    private var product: SKProduct?
//    private var proHandler: ((_: SKProduct) -> Void)?
//    private var purchaseHandler: ((_: Bool) -> Void)?
//
//    static var canMakePayments: Bool {
//        return SKPaymentQueue.canMakePayments()
//    }
//
//    private static var instance: InAppManager?
//    static var shared: InAppManager {
//        if instance == nil {
//            instance = InAppManager()
//            if let instance = instance {
//                SKPaymentQueue.default().add(instance)
//            }
//            instance?.update()
//        }
//        return instance!
//    }
//
//    var isPro: Bool {
//        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
//            if let _ = try? Data(contentsOf: appStoreReceiptURL) {
//                if UserDefaults.standard.bool(forKey: InAppManager.PRO_ID) {
//                    return true
//                }
//                return false
//            }
//        }
//        return false
//    }
//
//    func deactivate() {
//        SKPaymentQueue.default().remove(self)
//    }
//
//    func pro(_ block: @escaping (_: SKProduct) -> Void) {
//        if let product = product { block(product) }
//        else {
//            proHandler = block
//            update()
//        }
//    }
//
//    func purchase(_ block: @escaping (_: Bool) -> Void) {
//        pro { product in
//            self.purchaseHandler = block
//            let payment = SKPayment(product: product)
//            SKPaymentQueue.default().add(payment)
//        }
//    }
//
//    func restore(_ block: @escaping (_: Bool) -> Void) {
//        pro { product in
//            self.purchaseHandler = block
//            SKPaymentQueue.default().restoreCompletedTransactions()
//        }
//    }
//
//    private func update() {
//        productsRequest?.cancel()
//        let identifiers = Set([InAppManager.PRO_ID])
//        productsRequest = SKProductsRequest(productIdentifiers: identifiers)
//        productsRequest?.delegate = self
//        productsRequest?.start()
//    }
//
//    private func completeTransaction(_ transaction: SKPaymentTransaction) {
//        if transaction.payment.productIdentifier == product?.productIdentifier {
//            UserDefaults.standard.set(true, forKey: InAppManager.PRO_ID)
//            UserDefaults.standard.synchronize()
//            DispatchQueue.main.async {
//                self.purchaseHandler?(true)
//                self.purchaseHandler = nil
//            }
//        }
//        else {
//            DispatchQueue.main.async {
//                self.purchaseHandler?(false)
//                self.purchaseHandler = nil
//            }
//        }
//        SKPaymentQueue.default().finishTransaction(transaction)
//    }
//
//    private func restoreTransaction(_ transaction: SKPaymentTransaction) {
//        if transaction.original?.payment.productIdentifier == product?.productIdentifier {
//            UserDefaults.standard.set(true, forKey: InAppManager.PRO_ID)
//            UserDefaults.standard.synchronize()
//            DispatchQueue.main.async {
//                self.purchaseHandler?(true)
//                self.purchaseHandler = nil
//            }
//        }
//        else {
//            DispatchQueue.main.async {
//                self.purchaseHandler?(false)
//                self.purchaseHandler = nil
//            }
//        }
//        SKPaymentQueue.default().finishTransaction(transaction)
//    }
//
//    private func failedTransaction(_ transaction: SKPaymentTransaction) {
//        DispatchQueue.main.async {
//            self.purchaseHandler?(false)
//            self.purchaseHandler = nil
//        }
//        SKPaymentQueue.default().finishTransaction(transaction)
//    }
//
//}
//
//extension InAppManager: SKProductsRequestDelegate {
//    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
//        if let product = response.products.first {
//            self.product = product
//            DispatchQueue.main.async {
//                self.proHandler?(product)
//                self.productsRequest = nil
//            }
//        }
//    }
//    func request(_ request: SKRequest, didFailWithError error: Error) {
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
//            self.update()
//        }
//    }
//}
//
//extension InAppManager: SKPaymentTransactionObserver {
//    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
//        for transaction in transactions {
//            switch transaction.transactionState {
//            case .purchased:
//                completeTransaction(transaction)
//                print("purchased")
//            case .failed:
//                failedTransaction(transaction)
//                print("failedTransaction")
//            case .restored:
//                restoreTransaction(transaction)
//                print("restoreTransaction")
//            case .purchasing:
//                print("purchasing")
//                break
//            case .deferred:
//                print("deferred")
//                break
//            @unknown default:
//                break
//            }
//        }
//    }
//}

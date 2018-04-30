//
//  UNUserNotificationCenter+Rx.swift
//  RxUserNotifications
//
//  Created by Pawel Rup on 28.04.2018.
//  Copyright © 2018 Pawel Rup. All rights reserved.
//

import UserNotifications
import RxSwift
import RxCocoa

extension UNUserNotificationCenter: HasDelegate {
	public typealias Delegate = UNUserNotificationCenterDelegate
	
	public typealias DidReceiveResponseCompletionHandler = @convention(block) () -> Void
	public typealias WillPresentNotificationCompletionHandler = @convention(block) (UNNotificationPresentationOptions) -> Void
	
	public typealias DidReceiveResponseArguments = (response: UNNotificationResponse, completion: UNUserNotificationCenter.DidReceiveResponseCompletionHandler)
	public typealias WillPresentNotificationArguments = (notification: UNNotification, completion: UNUserNotificationCenter.WillPresentNotificationCompletionHandler)
}

private class RxUNUserNotificationCenterDelegateProxy: DelegateProxy<UNUserNotificationCenter, UNUserNotificationCenterDelegate>, DelegateProxyType, UNUserNotificationCenterDelegate {
	
	public weak private (set) var controller: UNUserNotificationCenter?
	
	public init(controller: ParentObject) {
		self.controller = controller
		super.init(parentObject: controller, delegateProxy: RxUNUserNotificationCenterDelegateProxy.self)
	}
	
	static func registerKnownImplementations() {
		self.register { RxUNUserNotificationCenterDelegateProxy(controller: $0) }
	}
}

extension Reactive where Base: UNUserNotificationCenter {
	
	public var delegate: DelegateProxy<UNUserNotificationCenter, UNUserNotificationCenterDelegate> {
		return RxUNUserNotificationCenterDelegateProxy.proxy(for: base)
	}
	
	public var willPresentNotification: Observable<UNUserNotificationCenter.WillPresentNotificationArguments> {
		return delegate.methodInvoked(#selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)))
			.map {
				let blockPointer = UnsafeRawPointer(Unmanaged<AnyObject>.passUnretained($0[2] as AnyObject).toOpaque())
				let handler = unsafeBitCast(blockPointer, to: UNUserNotificationCenter.WillPresentNotificationCompletionHandler.self)
				return ($0[1] as! UNNotification, handler)
		}
	}
	
	public var didReceiveResponse: Observable<UNUserNotificationCenter.DidReceiveResponseArguments> {
		return delegate.methodInvoked(#selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)))
			.map {
				let blockPointer = UnsafeRawPointer(Unmanaged<AnyObject>.passUnretained($0[2] as AnyObject).toOpaque())
				let handler = unsafeBitCast(blockPointer, to: UNUserNotificationCenter.DidReceiveResponseCompletionHandler.self)
				return ($0[1] as! UNNotificationResponse, handler)
		}
	}
}
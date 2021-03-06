/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 
 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

NS_ASSUME_NONNULL_BEGIN

#define _filenameFieldWithProgressBarYCord				4
#define _filenameFieldWithoutProgressBarYCord			12

#define _transferInfoFieldWithProgressBarYCord			6
#define _transferInfoFieldWithoutProgressBarYCord		16

@interface TDCFileTransferDialogTableCell ()
@property (readonly) TDCFileTransferDialogTransferController *cellItem;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, weak) IBOutlet NSImageView *fileIconView;
@property (nonatomic, weak) IBOutlet NSTextField *filenameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *filesizeTextField;
@property (nonatomic, weak) IBOutlet NSTextField *transferProgressTextField;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *filenameTextFieldConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *transferProgressTextFieldConstraint;
@property (readonly) BOOL isReceiving;
@property (readonly) TDCFileTransferDialogTransferStatus transferStatus;
@property (readonly) TXUnsignedLongLong processedFilesize;
@property (readonly) TXUnsignedLongLong totalFilesize;
@property (readonly) TXUnsignedLongLong currentRecord;
@property (readonly, copy) NSArray<NSNumber *> *speedRecords;
@property (readonly, copy, nullable) NSString *errorMessageDescription;
@property (readonly, copy, nullable) NSString *path;
@property (readonly, copy) NSString *filename;
@property (readonly, copy, nullable) NSString *filePath;
@property (readonly, copy) NSString *hostAddress;
@property (readonly, copy) NSString *peerNickname;
@property (readonly) uint16_t hostPort;
@end

@implementation TDCFileTransferDialogTableCell

#pragma mark -
#pragma mark Status Information

- (void)prepareInitialState
{
	NSString *filename = self.filename;

	self.filenameTextField.stringValue = filename;

	TXUnsignedLongLong totalFilesize = self.totalFilesize;

	NSString *totalFilesizeString = [NSByteCountFormatter stringFromByteCountWithPaddedDigits:totalFilesize];

	self.filesizeTextField.stringValue = totalFilesizeString;
	
	self.progressIndicator.doubleValue = 0;
	self.progressIndicator.minValue = 0;
	self.progressIndicator.maxValue = totalFilesize;

	NSImage *iconImage = [RZWorkspace() iconForFileType:filename.pathExtension];
	
	self.fileIconView.image = iconImage;

	[self reloadStatusInformation];
}

- (void)reloadStatusInformation
{
	[self performBlockOnMainThread:^{
		[self _reloadStatusInformation];
	}];
}

- (void)_reloadStatusInformation
{
	TDCFileTransferDialogTransferStatus transferStatus = self.transferStatus;

	BOOL transferIsStopped = (transferStatus == TDCFileTransferDialogTransferCompleteStatus ||
							  transferStatus == TDCFileTransferDialogTransferFatalErrorStatus ||
							  transferStatus == TDCFileTransferDialogTransferRecoverableErrorStatus ||
							  transferStatus == TDCFileTransferDialogTransferStoppedStatus ||
							  transferStatus == TDCFileTransferDialogTransferIsListeningAsSenderStatus ||
							  transferStatus == TDCFileTransferDialogTransferIsListeningAsReceiverStatus ||
							  transferStatus == TDCFileTransferDialogTransferInitializingStatus ||
							  transferStatus == TDCFileTransferDialogTransferMappingListeningPortStatus ||
							  transferStatus == TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus ||
							  transferStatus == TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus ||
							  transferStatus == TDCFileTransferDialogTransferWaitingForResumeAcceptStatus);

	TXUnsignedLongLong processedFilesize = self.processedFilesize;

	if (transferIsStopped) {
		if (self.progressIndicator.hidden == NO) {
			self.progressIndicator.hidden = YES;

			self.filenameTextFieldConstraint.constant = _filenameFieldWithoutProgressBarYCord;

			self.transferProgressTextFieldConstraint.constant = _transferInfoFieldWithoutProgressBarYCord;

			[self layoutSubtreeIfNeeded];
		}
	} else {
		if (self.progressIndicator.hidden) {
			self.progressIndicator.hidden = NO;

			self.filenameTextFieldConstraint.constant = _filenameFieldWithProgressBarYCord;

			self.transferProgressTextFieldConstraint.constant = _transferInfoFieldWithProgressBarYCord;

			[self layoutSubtreeIfNeeded];
		}
	}

	if (transferIsStopped == NO) {
		if (transferStatus == TDCFileTransferDialogTransferConnectingStatus) {
			self.progressIndicator.indeterminate = YES;

			[self.progressIndicator startAnimation:nil];
		} else {
			self.progressIndicator.indeterminate = NO;

			self.progressIndicator.doubleValue = self.processedFilesize;
		}
	}

	switch (transferStatus) {
		case TDCFileTransferDialogTransferStoppedStatus:
		{
			if (self.isReceiving) {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1009]", self.peerNickname);
			} else {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1001]", self.peerNickname);
			}
			
			break;
		}
		case TDCFileTransferDialogTransferMappingListeningPortStatus:
		{
			if (self.isReceiving) {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1010]", self.peerNickname);
			} else {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1002]", self.peerNickname);
			}

			break;
		}
		case TDCFileTransferDialogTransferWaitingForLocalIPAddressStatus:
		{
			if (self.isReceiving) {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1011]", self.peerNickname);
			} else {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1003]", self.peerNickname);
			}

			break;
		}
		case TDCFileTransferDialogTransferInitializingStatus:
		{
			if (self.isReceiving) {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1013]", self.peerNickname);
			} else {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1004]", self.peerNickname);
			}

			break;
		}
		case TDCFileTransferDialogTransferIsListeningAsSenderStatus:
		{
			self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1005]", self.peerNickname);

			break;
		}
		case TDCFileTransferDialogTransferIsListeningAsReceiverStatus:
		{
			self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1014]", self.peerNickname);
			
			break;
		}
		case TDCFileTransferDialogTransferFatalErrorStatus:
		case TDCFileTransferDialogTransferRecoverableErrorStatus:
		{
			self.transferProgressTextField.stringValue = self.errorMessageDescription;
			
			break;
		}
		case TDCFileTransferDialogTransferCompleteStatus:
		{
			if (self.isReceiving) {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1015]", self.peerNickname);
			} else {
				self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1006]", self.peerNickname);
			}

			break;
		}
		case TDCFileTransferDialogTransferSendingStatus:
		case TDCFileTransferDialogTransferReceivingStatus:
		{
			/* Format time remaining */
			NSTimeInterval timeRemaining = 0;
			
			NSString *timeRemainingString = nil;

			TXUnsignedLongLong currentSpeed = self.currentSpeed;
			
			if (currentSpeed > 0) {
				timeRemaining = ((self.totalFilesize - processedFilesize) / currentSpeed);
				
				if (timeRemaining > 0) {
					timeRemainingString = TXHumanReadableTimeInterval(timeRemaining, YES, (NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond));
				}
			}
			
			/* Update status */
			NSString *totalFilesizeString = self.filesizeTextField.stringValue;

			NSString *currentSpeedString = [NSByteCountFormatter stringFromByteCountWithPaddedDigits:currentSpeed];
			NSString *processedFilesizeString = [NSByteCountFormatter stringFromByteCountWithPaddedDigits:processedFilesize];
			
			NSString *statusString = nil;

			if (self.isReceiving) {
				if (timeRemainingString) {
					statusString = TXTLS(@"TDCFileTransferDialog[1008][2]", processedFilesizeString, totalFilesizeString, currentSpeedString, self.peerNickname, timeRemainingString);
				} else {
					statusString = TXTLS(@"TDCFileTransferDialog[1008][1]", processedFilesizeString, totalFilesizeString, currentSpeedString, self.peerNickname);
				}
			} else {
				if (timeRemainingString) {
					statusString = TXTLS(@"TDCFileTransferDialog[1000][2]", processedFilesizeString, totalFilesizeString, currentSpeedString, self.peerNickname, timeRemainingString);
				} else {
					statusString = TXTLS(@"TDCFileTransferDialog[1000][1]", processedFilesizeString, totalFilesizeString, currentSpeedString, self.peerNickname);
				}
			}
			
			self.transferProgressTextField.stringValue = statusString;
			
			break;
		}
		case TDCFileTransferDialogTransferConnectingStatus:
		{
			self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1016]", self.peerNickname);
			
			break;
		}
		case TDCFileTransferDialogTransferWaitingForReceiverToAcceptStatus:
		{
			self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1007]", self.peerNickname);

			break;
		}
		case TDCFileTransferDialogTransferWaitingForResumeAcceptStatus:
		{
			self.transferProgressTextField.stringValue = TXTLS(@"TDCFileTransferDialog[1012]", self.peerNickname);

			break;
		}
	}
	
	/* Update clear button */
	[self updateClearButton];
}

#pragma mark -
#pragma mark Proxy Methods

- (void)updateClearButton
{
	[self.cellItem updateClearButton];
}

- (void)onMaintenanceTimer
{
	[self.cellItem onMaintenanceTimer];
}

#pragma mark -
#pragma mark Properties

- (TDCFileTransferDialogTransferController *)cellItem
{
	return self.objectValue;
}

- (TDCFileTransferDialogTransferStatus)transferStatus
{
	return self.cellItem.transferStatus;
}

- (BOOL)isReceiving
{
	return (self.cellItem.isSender == NO);
}

- (nullable NSString *)path
{
	return self.cellItem.path;
}

- (NSString *)filename
{
	return self.cellItem.filename;
}

- (nullable NSString *)filePath
{
	return self.cellItem.filePath;
}

- (NSString *)peerNickname
{
	return self.cellItem.peerNickname;
}

- (nullable NSString *)errorMessageDescription
{
	return self.cellItem.errorMessageDescription;
}

- (NSString *)hostAddress
{
	return self.cellItem.hostAddress;
}

- (uint16_t)hostPort
{
	return self.cellItem.hostPort;
}

- (TXUnsignedLongLong)totalFilesize
{
	return self.cellItem.totalFilesize;
}

- (TXUnsignedLongLong)processedFilesize
{
	return self.cellItem.processedFilesize;
}

- (TXUnsignedLongLong)currentRecord
{
	return self.cellItem.currentRecord;
}

- (TXUnsignedLongLong)currentSpeed
{
	NSArray *speedRecords = self.speedRecords;

	if (speedRecords.count == 0) {
		return 0;
	}

	TXUnsignedLongLong totalTransferred = 0;

	for (NSNumber *record in speedRecords) {
		totalTransferred += record.unsignedLongLongValue;
	}

	return (totalTransferred / speedRecords.count);
}

- (NSArray<NSNumber *> *)speedRecords
{
	return self.cellItem.speedRecords;
}

@end

NS_ASSUME_NONNULL_END

import { LightningElement, api, track, wire } from 'lwc';
import cancelOrderDeliveryGroupByCSR from '@salesforce/apex/OrderController.cancelOrderDeliveryGroupByCSR';
import getCancelMessageOrderDeliveryGroupByCSR from '@salesforce/apex/OrderController.getCancelMessageOrderDeliveryGroupByCSR';
import releaseOrderDeliveryGroupByCSR from '@salesforce/apex/OrderController.releaseOrderDeliveryGroupByCSR';
import getReleaseMessageOrderDeliveryGroupByCSR from '@salesforce/apex/OrderController.getReleaseMessageOrderDeliveryGroupByCSR';
import getPlantCode from '@salesforce/apex/OrderController.getPlantCode';
import { refreshApex } from '@salesforce/apex';

import Amend_Order_Access_Code from '@salesforce/label/c.Amend_Order_Access_Code';
import Amend_Order_BOL_Number from '@salesforce/label/c.Amend_Order_BOL_Number';
import Amend_Order_Canceled_By from '@salesforce/label/c.Amend_Order_Canceled_By';
import Amend_Order_Canceled_On from '@salesforce/label/c.Amend_Order_Canceled_On';
import Amend_Order_Cancellation_Request_By from '@salesforce/label/c.Amend_Order_Cancellation_Request_By';
import Amend_Order_Cancellation_Request_Cancel from '@salesforce/label/c.Amend_Order_Cancellation_Request_Cancel';
import Amend_Order_Cancellation_Request_On from '@salesforce/label/c.Amend_Order_Cancellation_Request_On';
import Amend_Order_Cancel_Button from '@salesforce/label/c.Amend_Order_Cancel_Button';

import Amend_Order_Cancel_Proceed_Confirmation_Message from '@salesforce/label/c.Amend_Order_Cancel_Proceed_Confirmation_Message';
import Amend_Order_Edit from '@salesforce/label/c.Amend_Order_Edit';
import Amend_Order_Edit_Button from '@salesforce/label/c.Amend_Order_Edit_Button';
import Amend_Order_Product_Code from '@salesforce/label/c.Amend_Order_Product_Code';

import Amend_Order_Quote_Number from '@salesforce/label/c.Amend_Order_Quote_Number';
import Amend_Order_Plant_Code from '@salesforce/label/c.Amend_Order_Plant_Code';
import Amend_Order_Release from '@salesforce/label/c.Amend_Order_Release';
import Amend_Order_Released_By from '@salesforce/label/c.Amend_Order_Released_By';
import Amend_Order_Released_On from '@salesforce/label/c.Amend_Order_Released_On';
import Amend_Order_Release_Button from '@salesforce/label/c.Amend_Order_Release_Button';

import Amend_Order_Release_Confirmation_Message from '@salesforce/label/c.Amend_Order_Release_Confirmation_Message';
import Amend_Order_Shipping_Date from '@salesforce/label/c.Amend_Order_Shipping_Date';
import Amend_Order_Shipping_Weight from '@salesforce/label/c.Amend_Order_Shipping_Weight';
import Amend_Order_Status from '@salesforce/label/c.Amend_Order_Status';

export default class CarmeuseAmendOrderSummeryLineItem extends LightningElement {

    @api eachDeliveryDateWrapper;
    @api accountId;
    @api currentRecordId;
	@api errorMessage;
    @track productCode;
    @track plantCode;
    @track items = [];
    @track isDialogVisible = false;
    @track originalMessage;
    @track isReleaseDialogVisible = false;
    @track originalReleaseMessage;
    @track displayMessage = 'Click on the \'Open Confirmation\' button to test the dialog.';
    recordIds = [];
    releasedOrCancelledRecordIds = [];
    quoteNums = [];
    listOfQuoteNumbers = [];
    quoteNumber;
    editOrderDeliveryGroupId;
    cancelOrderDeliveryGroupId;
    releaseOrderDeliveryGroupId;
    //releasedIdHolder;

    label = {
        Amend_Order_Access_Code,
        Amend_Order_BOL_Number,
        Amend_Order_Canceled_By,
        Amend_Order_Canceled_On,
        Amend_Order_Cancellation_Request_By,
        Amend_Order_Cancellation_Request_Cancel,
        Amend_Order_Cancellation_Request_On,
        Amend_Order_Cancel_Button,
        Amend_Order_Cancel_Proceed_Confirmation_Message,
        Amend_Order_Edit,
        Amend_Order_Edit_Button,
        Amend_Order_Product_Code,
        Amend_Order_Plant_Code,
        Amend_Order_Quote_Number,
        Amend_Order_Release,
        Amend_Order_Released_By,
        Amend_Order_Released_On,
        Amend_Order_Release_Button,
        Amend_Order_Release_Confirmation_Message,
        Amend_Order_Shipping_Date,
        Amend_Order_Shipping_Weight,
        Amend_Order_Status
    }

    connectedCallback() {
        getPlantCode({ accountId: this.accountId })
        .then(result => {
            this.listOfQuoteNumbers = result;
            console.log(result);
            this.listOfQuoteNumbers.forEach(element => {
                var fields = element.split('|');
                fields[0] = fields[0].trim();
                fields[1] = fields[1].trim();
                this.eachDeliveryDateWrapper.orderDeliveryGroupSummaryWrapperList.forEach(lineItem => {
                    let plantCodeelement = this.template.querySelector('[data-plantcode="' + lineItem.originalOrderDeliveryGroupId + '"]');
                    if(fields[0] == lineItem.quoteNumber){
                        plantCodeelement.innerHTML = fields[1];
                    }
                });
            });
        })
        .catch(error => {
            console.log(error);                        
        });
    }

    handledChange(event){
        if(event.target.name==='quoteNumber'){
            //console.log('handle Change'+event.target.value);
            this.quoteNumber = event.target.value;
        }
    }

    handleProgressValueChange(event) {       
        
        let materialelement = this.template.querySelector('[data-materialid="' + event.detail.odgId + '"]');
        let plantCodeelement = this.template.querySelector('[data-plantcode="' + event.detail.odgId + '"]');
        let quoteelement = this.template.querySelector('[data-quote="' + event.detail.odgId + '"]');

        if(materialelement != null){            
            materialelement.innerHTML = event.detail.material;
        }
        if(plantCodeelement != null){
            plantCodeelement.innerHTML = event.detail.plantCode;
        }
        if(quoteelement != null){            
            quoteelement.innerHTML = event.detail.quote;
        }
    }

    handleCancel(event){
        
        if(event.target.name === 'confirmModal'){

            //when user clicks outside of the dialog area, the event is dispatched with detail value  as 1
            if(event.detail !== 1){
                if(event.detail.status === 'confirm') {                    
                    let element = this.template.querySelector('[data-id="' + this.cancelOrderDeliveryGroupId + '"]');
                    let statuselement = this.template.querySelector('[data-statusid="' + this.cancelOrderDeliveryGroupId + '"]');
                    let cancelButton = this.template.querySelector('[data-btn="' + this.cancelOrderDeliveryGroupId + '"]');
                    let editButton = this.template.querySelector('[data-editbtn="' + this.cancelOrderDeliveryGroupId + '"]');
                    let releaseButton = this.template.querySelector('[data-releasebtn="' + this.cancelOrderDeliveryGroupId + '"]');
                    cancelButton.classList.toggle('slds-hide'); 

                    element.innerHTML = 'Cancellation in progress';                    
                    cancelOrderDeliveryGroupByCSR({ orderDeliveryGroupId: this.cancelOrderDeliveryGroupId})
                    .then(result => {
                        
                        
                        getCancelMessageOrderDeliveryGroupByCSR({ orderDeliveryGroupId: this.cancelOrderDeliveryGroupId})
                        .then(result => {
                            
                            if(editButton != null){
                                editButton.classList.toggle('slds-hide');    
                            }
                            if(releaseButton != null){                                
                                releaseButton.classList.add('slds-hide');    
                            } 
                            element.innerHTML = result; 
                            statuselement.innerHTML = 'Cancelled';
                        })
                        .catch(error => {
                                
                            cancelButton.classList.toggle('slds-hide');
                            element.innerHTML = '';                        
                        });

                        this.releasedOrCancelledRecordIds.push(this.cancelOrderDeliveryGroupId);

                    })
                    .catch(error => {
                          
                        cancelButton.classList.toggle('slds-hide');
                        element.innerHTML = '';                    
                    });
                } else if(event.detail.status === 'cancel'){
                    console.log('do nothing');
                }
            }

            //hides the component
            this.isDialogVisible = false;
        }
    }

    handleConfirmation(event){
        this.originalMessage = '';
        this.cancelOrderDeliveryGroupId = event.target.name;
        //shows the component
        this.isDialogVisible = true;

        // this.eachDeliveryDateWrapper.orderDeliveryGroupSummaryWrapperList.forEach(element => {
        //     if(element.orderDeliveryGroupId == this.cancelOrderDeliveryGroupId) {
        //         element.isOrderCanceledByCSR = true;
        //         console.log("Cancelled: ", element.isOrderCanceledByCSR);
        //     }
        // });
    }

    handleReleaseConfirmation(event){
        this.originaReleaselMessage = '';
        this.releaseOrderDeliveryGroupId = event.target.name;
        //this.releasedIdHolder = event.target.name;
        // this.eachDeliveryDateWrapper.orderDeliveryGroupSummaryWrapperList.forEach(element => {
        //     console.log(element.orderDeliveryGroupId, " ", this.releaseOrderDeliveryGroupId)
        //     if(element.orderDeliveryGroupId == this.releaseOrderDeliveryGroupId) {
        //         element.isOrderReleasedByCSR = true;
        //         console.log("Released: ", element.isOrderReleasedByCSR);
        //     }
        // });
        //shows the component
        this.template.querySelector('c-confirmation-dialog').setAttribute('message','Do you want to release an order?');
        this.template.querySelector('c-confirmation-dialog').setAttribute('title','Confirm Order Release');
        //this.template.querySelector('c-confirmation-dialog').setAttribute('onclick','{handleRelease}');
        this.template.querySelector('c-confirmation-dialog').addEventListener('click',
        this.handleRelease);
        this.isReleaseDialogVisible = true;
    }

    handleRelease(event){
        if(event.target.name === 'confirmReleaseModal'){

            //when user clicks outside of the dialog area, the event is dispatched with detail value  as 1
            if(event.detail !== 1){
                if(event.detail.status === 'confirm') {
                    let releaseButton = this.template.querySelector('[data-releasebtn="' + this.releaseOrderDeliveryGroupId + '"]');
                    let relelement = this.template.querySelector('[data-relid="' + this.releaseOrderDeliveryGroupId + '"]');
                    let cancelButton = this.template.querySelector('[data-btn="' + this.releaseOrderDeliveryGroupId + '"]');
                    let editButton = this.template.querySelector('[data-editbtn="' + this.releaseOrderDeliveryGroupId + '"]');
                    releaseButton.classList.toggle('slds-hide');
                    relelement.innerHTML = 'Release in progress';   
                                     
                    releaseOrderDeliveryGroupByCSR({ orderDeliveryGroupId: this.releaseOrderDeliveryGroupId})
                    .then(result => {
                        
                        getReleaseMessageOrderDeliveryGroupByCSR({ orderDeliveryGroupId: this.releaseOrderDeliveryGroupId})
                        .then(result => {
                            console.log(result);
                            relelement.innerHTML = result;
                            if(cancelButton != null){                                
                                cancelButton.classList.add('slds-hide');    
                            } 
                            if(editButton != null){                                
                                editButton.classList.add('slds-hide');    
                            } 

                            //releasedOrCancelledRecordIds.push(this.releasedIdHolder);
                        })
                        .catch(error => {
                            console.log(error);
                            releaseButton.classList.toggle('slds-hide');
                            relelement.innerHTML = '';                        
                        });

                        //console.log("Released Id: ", this.releaseOrderDeliveryGroupId);
                        this.releasedOrCancelledRecordIds.push(this.releaseOrderDeliveryGroupId);

                    })
                    .catch(error => {
                        console.log(error);
                        releaseButton.classList.toggle('slds-hide');
                        relelement.innerHTML = '';                         
                    });
                } else if(event.detail.status === 'cancel'){
                    console.log('do nothing');
                }
            }
            //hides the component
            this.isReleaseDialogVisible = false;
        }
    }

    handleUpdate(event){
        this.editOrderDeliveryGroupId = event.target.name;
        this.template.querySelector('c-order-delivery-group-modal').setAttribute('record-id',event.target.name);
        this.template.querySelector('c-order-delivery-group-modal').handlePopup(event.target.name);
    } 

    handleEditAll(event){
        //console.log("eachDeliveryDateWrapper.orderDeliveryGroupSummaryWrapperList: ", event.target.name);
        //console.log("List of released Ids: ", this.releasedOrCancelledRecordIds);
        var releasedFlag = false;
        this.recordIds = [];
        this.eachDeliveryDateWrapper.orderDeliveryGroupSummaryWrapperList.forEach(element => {
            releasedFlag = false;
            this.releasedOrCancelledRecordIds.forEach(releasedId => {
                if(element.originalOrderDeliveryGroupId == releasedId) {
                    //console.log("Found match... not adding ", element.originalOrderDeliveryGroupId);
                    releasedFlag = true;
                }
            });
            if(element.isOrderCanceledByCSR == false && element.isOrderReleasedByCSR == false && releasedFlag == false) {
                //console.log("Adding ", element.originalOrderDeliveryGroupId);
                this.recordIds.push(element.originalOrderDeliveryGroupId);
            }
        });

        if(this.recordIds.length != 0) {
            this.template.querySelector('c-order-delivery-group-modal-edit-all').handlePopup(this.recordIds);
        }
        else {
            var editAllButton = this.template.querySelector(".editAll")
            //editAllButton.disabled = true;
        }
    }
}
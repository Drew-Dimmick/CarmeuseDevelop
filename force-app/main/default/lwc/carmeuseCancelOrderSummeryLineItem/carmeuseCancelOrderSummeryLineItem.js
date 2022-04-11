import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import cancelOrderDeliveryGroupByPortalUser from '@salesforce/apex/OrderController.cancelOrderDeliveryGroupByPortalUser';
import Order_Detail_Product_Code from '@salesforce/label/c.Order_Detail_Product_Code';
import Order_Detail_Access_Code from '@salesforce/label/c.Order_Detail_Access_Code';
import Order_Detail_BOL_Number from '@salesforce/label/c.Order_Detail_BOL_Number';
import Order_Detail_Status from '@salesforce/label/c.Order_Detail_Status';
import Order_Detail_Shipping_DateTime from '@salesforce/label/c.Order_Detail_Shipping_DateTime';
import Order_Detail_Shipping_Weight from '@salesforce/label/c.Order_Detail_Shipping_Weight';

export default class CarmeuseCancelOrderSummeryLineItem extends NavigationMixin(LightningElement) {

    @api eachDeliveryDateWrapperClone;
    @api orderId;
    @api productCode;
    @api deliveryDate;
    @track eachDeliveryDateWrapper;
    @track payloadForCancelOrder = {orderId : null, lstOrderItemsToCancel:[]};
    @track orderItemsToCancel;
    @track index;
    @track showConfirmationModal = false;
    @track label = {
        Order_Detail_Product_Code,
        Order_Detail_BOL_Number,
        Order_Detail_Access_Code,
        Order_Detail_Status,
        Order_Detail_Shipping_DateTime,
        Order_Detail_Shipping_Weight
    };

    
    connectedCallback() {
        this.eachDeliveryDateWrapper = JSON.parse(JSON.stringify(this.eachDeliveryDateWrapperClone)); 
    }

    handleRequestForCancel(event) {
        let index = this.index;
        this.handleModalCancel();

        let deliveryDate = new Date((this.deliveryDate).split('/'));
            
        let cutOffDay = deliveryDate.setDate(deliveryDate.getDate() - 1 );
        let cutOffDate = new Date(cutOffDay);
        cutOffDate.setHours(14,0,0,0);
        let today = new Date();

        if(today > cutOffDate) {
            this.showNotification('You have missed the cut off date!', 'error', 'ERROR');
            before;
        }
            
        
        cancelOrderDeliveryGroupByPortalUser({orderDeliveryGroupId: this.eachDeliveryDateWrapper.orderDeliveryGroupSummaryWrapperList[index].originalOrderDeliveryGroupId, 
                                                orderId: this.orderId})
        .then(result => {
            this.eachDeliveryDateWrapper.orderDeliveryGroupSummaryWrapperList[index].isOrderRequestedForCancellation = true;
            this.index = null;
            this.showNotification('Cancel request Raised!', 'success', 'SUCCESS');
            
        })
        .catch(error => {
           console.log(error);
           this.showNotification('Something went wrong!', 'error', 'ERROR');

           this.index = null; 

        })

    }

    navigateToBOLDetail(event) {
        //let bolNumber = this.template.querySelector(".BOLNumber");
        let bolNumber = event.target.dataset.id;
        var odgId;

        console.log("BOL Number: ", bolNumber);

        this.eachDeliveryDateWrapper.orderDeliveryGroupSummaryWrapperList.forEach(eachDeliveryDateLineItemWrapper => {
            if(eachDeliveryDateLineItemWrapper.bolNumber == bolNumber) {
                odgId = eachDeliveryDateLineItemWrapper.Id;
            }
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: odgId,
                objectApiName: 'OrderDeliveryGroup',
                actionName: 'view',
            },
        });
    }

    handleShowConfirmationModal(event) {
        this.index = parseInt(event.detail);
        this.showConfirmationModal = true;
    }

    handleModalCancel(){
        this.showConfirmationModal = false;
    }

    
    showNotification(message, variant, title) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

}
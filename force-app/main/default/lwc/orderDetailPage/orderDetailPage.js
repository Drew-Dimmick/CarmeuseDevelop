import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import getOrderItemSummary from "@salesforce/apex/OrderController.getOrderSummaryByOriginalOrderId";
import getOrder from "@salesforce/apex/OrderController.getOrderByOrderId";

export default class OrderDetailPage extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference)
    pageRef;
    @api recordId;
    @track orderNumber;
    @track orderSummaryId;
    @track orderSummaryNumber;
    @track effectiveDate;
    @track status;
    @track accountOwner;
    @track orderOwner;

    connectedCallback() {
        console.log("Record Id: " + this.recordId);
    }

    @wire(getOrder, { orderId: '$recordId' })
    wiredOrder ({ error, data }) {
        if(data) {
            this.orderNumber = data.OrderNumber;
            this.effectiveDate = data.EffectiveDate;
            this.status = data.Status;
            //this.accountOwner = data.AccountId__r.Name;
            //this.orderOwner = data.OwnerId__r.Name;
        } else if (error) {
            this.error = error;
            console.log(this.error);
        }
    }

    @wire(getOrderItemSummary, { originalOrderId: '$recordId' })
    wiredOrderSummary ({ error, data }) {
        if(data) {
            data.forEach((record) => {
                this.orderSummaryNumber = record.OrderNumber;
                this.orderSummaryId = record.Id;
                console.log("Order Summary Id:", this.orderSummaryId);
            });
        } else if (error) {
            this.error = error;
            console.log(this.error);
        }
    }

    navigateToOrderSummaryDetail() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.orderSummaryId,
                objectApiName: 'OrderSummary',
                actionName: 'view',
            },
        });
    }
}
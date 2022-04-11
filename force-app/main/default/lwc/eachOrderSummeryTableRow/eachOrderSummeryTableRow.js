import { LightningElement, api, track } from 'lwc';

export default class EachOrderSummeryTableRow extends LightningElement {
    
    @api eachDeliveryDateLineItemWrapper;
    @api productCode;
    @api index;

    

    get disableCancelButton() {
        return this.eachDeliveryDateLineItemWrapper.isOrderRequestedForCancellation || 
                this.eachDeliveryDateLineItemWrapper.shipmentStatus == 'Shipped' ||
                this.eachDeliveryDateLineItemWrapper.shipmentStatus == 'Cancelled' ||
                this.eachDeliveryDateLineItemWrapper.shipmentStatus == 'Pending';
    }

    handleShowConfirmationModal(event) {
        this.dispatchEvent(new CustomEvent('showconfirmationmodal' ,{detail: this.index}));
    }

}
import { LightningElement, api, wire, track } from 'lwc';
import getOrderDeliveryGroups from "@salesforce/apex/OrderController.getOrderDeliveryGroupByOrderId";

export default class OrderDeliveryGroup extends LightningElement {
    @api recordId;
    @track isResponse = false;
    @track wrapper;

    @wire(getOrderDeliveryGroups, { orderId: '$recordId' })
    wiredOrderDeliveryGroups ({ error, data }) {
        if(data) {
            this.wrapper = data;
            this.isResponse = true;
        } else if (error) {
            this.error = error;
            console.log(this.error);
        }
    }
}
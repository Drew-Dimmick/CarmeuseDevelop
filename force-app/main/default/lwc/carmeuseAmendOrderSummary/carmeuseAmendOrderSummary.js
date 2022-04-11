import { LightningElement, track, api } from 'lwc';
import getOrderDetail from '@salesforce/apex/OrderController.getOrderDetail';
export default class CarmeuseAmendOrderSummary extends LightningElement {

    @track wrapper;
    @track err;
    @track isResponse = false;
    @api recordId;
    @track roughData = '';
    @api productCode;
    @api currentRecordId;
	 @api errorMessage; 
    addOrderDeliveryGroupId;
  
    connectedCallback(){
       //this.wrapper = JSON.parse(this.roughData);
        getOrderDetail({orderId : this.recordId})
           .then(result =>{
              this.wrapper = result;
              this.isResponse = true;
              console.log(JSON.stringify(result));
              console.log(result);
          }).catch(error =>{
            this.err = error;
         });
    }
}
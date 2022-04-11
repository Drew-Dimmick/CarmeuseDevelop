import { LightningElement, api, track } from 'lwc';
import Order_Detail_Ship_To_Address from '@salesforce/label/c.Order_Detail_Ship_To_Address';
import Order_Detail_Tonnage from '@salesforce/label/c.Order_Detail_Tonnage';
import Order_Detail_Requested_Delivery_Date from '@salesforce/label/c.Order_Detail_Requested_Delivery_Date';
import Order_Detail_Shipping_Mode from '@salesforce/label/c.Order_Detail_Shipping_Mode';
import Order_Detail_Deliveries_Required from '@salesforce/label/c.Order_Detail_Deliveries_Required';
import Order_Detail_Load_Volume from '@salesforce/label/c.Order_Detail_Load_Volume';
import Order_Detail_PO_Number from '@salesforce/label/c.Order_Detail_PO_Number';
import Order_Detail_Delivery_Text from '@salesforce/label/c.Order_Detail_Delivery_Text';


export default class CarmeuseCancelOrderAccordionSection extends LightningElement {

    @api productInstance;
    @api orderId;
    @track label = {
        Order_Detail_Ship_To_Address,
        Order_Detail_Tonnage,
        Order_Detail_Requested_Delivery_Date,
        Order_Detail_Shipping_Mode,
        Order_Detail_Deliveries_Required,
        Order_Detail_Load_Volume,
        Order_Detail_PO_Number,
        Order_Detail_Delivery_Text
    };
    get accordionSectionLabel(){
        return `${this.productInstance.productName} (Total Volume: ${this.productInstance.totalVolume})`;
    }
}
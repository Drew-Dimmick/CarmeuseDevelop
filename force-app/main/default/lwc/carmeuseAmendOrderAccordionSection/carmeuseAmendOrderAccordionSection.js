import { LightningElement, api } from 'lwc';
import Amend_Order_L2_Tonnage from '@salesforce/label/c.Amend_Order_L2_Tonnage';
import Amend_Order_L2_Ship_To_Address from '@salesforce/label/c.Amend_Order_L2_Ship_To_Address';
import Amend_Order_L2_Shipping_Mode from '@salesforce/label/c.Amend_Order_L2_Shipping_Mode';
import Amend_Order_L2_Requested_Delivery_Date from '@salesforce/label/c.Amend_Order_L2_Requested_Delivery_Date';
import Amend_Order_L2_PO_Number from '@salesforce/label/c.Amend_Order_L2_PO_Number';
import Amend_Order_L2_Load_Volume from '@salesforce/label/c.Amend_Order_L2_Load_Volume';
import Amend_Order_L2_Delivery_Text from '@salesforce/label/c.Amend_Order_L2_Delivery_Text';
import Amend_Order_L2_Deliveries_Required from '@salesforce/label/c.Amend_Order_L2_Deliveries_Required';

export default class CarmeuseAmendOrderAccordionSection extends LightningElement {

    @api productInstance;
    @api orderId;
    @api accountId;

    label = {
        Amend_Order_L2_Tonnage,
        Amend_Order_L2_Ship_To_Address,
        Amend_Order_L2_Shipping_Mode,
        Amend_Order_L2_Requested_Delivery_Date,
        Amend_Order_L2_PO_Number,
        Amend_Order_L2_Load_Volume,
        Amend_Order_L2_Delivery_Text,
        Amend_Order_L2_Deliveries_Required
    }

    get accordionSectionLabel(){
        return `${this.productInstance.productName} (Total Volume: ${this.productInstance.shipmentTonnage})`;
    }


}
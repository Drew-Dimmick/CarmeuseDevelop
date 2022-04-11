import { LightningElement ,api, wire, track} from 'lwc';
import getOrderSummary from '@salesforce/apex/OrderController.getOrderSummary';



export default class OrderSummaryList extends LightningElement {
    @track columns = [{
            label: 'Order Summary Number',
            fieldName: 'OrderNumber',
            type: 'text',
            sortable: true
        },
        {
            label: 'Status',
            fieldName: 'Status',
            type: 'text',
            sortable: true
        },
        {
            label: 'Ordered Date',
            fieldName: 'OrderedDate',
            type: 'Date/Time',
            sortable: true
        }
    ];
 
    @wire(getOrderSummary) orderList;
}
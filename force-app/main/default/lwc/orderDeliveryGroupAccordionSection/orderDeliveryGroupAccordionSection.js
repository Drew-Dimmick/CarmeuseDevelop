import { LightningElement, api, track } from 'lwc';

export default class OrderDeliveryGroupAccordionSection extends LightningElement {
    @api orderDeliveryGroup;
    @api orderDeliveryGroupId;
}
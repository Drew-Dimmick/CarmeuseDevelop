import { LightningElement, api } from 'lwc';
import communityUrl from '@salesforce/community/basePath';
import { NavigationMixin } from 'lightning/navigation';
import deleteCartRecord from "@salesforce/apex/B2BCartController.deleteCartRecord";

export default class ClearCart extends NavigationMixin(LightningElement) {
    @api recordId;

    deleteCart() {
        deleteCartRecord({
            cartId: this.recordId
        }).then(response => {
            //location.reload();
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'home'
                },
            });
        }).catch(error => {
            console.warn(error);
        });
    }
}
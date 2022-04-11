import { LightningElement, wire, track, api } from 'lwc';
import showPopup from '@salesforce/apex/OrderUtils.shouldUserSeeSurveyPopup';
export default class OrderConfirmationSurveyPopup extends LightningElement {
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @api effectiveAccountId;
    @track isModalOpen = false;
    @track remainder;
    @track error;
    
    connectedCallback() {
        this.checkToShowPopup();
    }

    checkToShowPopup(){
        showPopup({ accountId: this.effectiveAccountId })
            .then(result => {
                if(result){
                    this.remainder = result;
                    console.log('Remainder: ', this.remainder);
                }
                else {
                    this.isModalOpen = true;
                }
            })
            .catch(error => {
                console.log('Error: ', error);
            })
    }

    getRandomInt(max) {
        return Math.floor(Math.random() * max);
    }

    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }
    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        this.isModalOpen = false;
    }
}
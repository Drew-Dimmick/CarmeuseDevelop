import { LightningElement, api, track } from 'lwc';
import getPONumber from '@salesforce/apex/OrderController.getPONumber';
import getProduct from '@salesforce/apex/OrderUtils.getProductById';
import Split_Shipment_Deliveries_Required from '@salesforce/label/c.Split_Shipment_Deliveries_Required';
import Split_Shipment_Delivery_End_Date from '@salesforce/label/c.Split_Shipment_Delivery_End_Date';
import Split_Shipment_Delivery_Start_Date from '@salesforce/label/c.Split_Shipment_Delivery_Start_Date';
import Split_Shipment_Delivery_Text from '@salesforce/label/c.Split_Shipment_Delivery_Text';
import Split_Shipment_Line_Item_Delivery_Date from '@salesforce/label/c.Split_Shipment_Line_Item_Delivery_Date';
import Split_Shipment_Load_Volume from '@salesforce/label/c.Split_Shipment_Load_Volume';
import Split_Shipment_PO_Number from '@salesforce/label/c.Split_Shipment_PO_Number';
import Same_Day_Delivery_Warning from '@salesforce/label/c.Same_Day_Delivery_Warning';
import Split_Shipment_Select_Product from '@salesforce/label/c.Split_Shipment_Select_Product';
import Split_Shipment_Shipping_Mode from '@salesforce/label/c.Split_Shipment_Shipping_Mode';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SplitShipmentProductDetails extends LightningElement {

    @api recordId;
    @api accountId;
    @api selectedProduct;
    @api mapOfProductIdVsName;
    @api mapOfProductNameVsId;
    @api mapOfIndexVsProductDetail;
    @api mapOfProductIdVsAvailable;
    @track lineItemsGenerated = false;
    @track selectedMeasure;
    @track selectedStartDate;
    @track selectedEndDate;
    @track selectedNumberOfRecurring;
    @track selectedShippingMode;
    @track shippingMode;
    @track loadVolumeLabel = "Load Volume";
    @track selectedQuantity;
    @track enteredPoNumber;
    @track today;
    @track maxDate;
    @track cartItems;
    @track enteredDeliveryText;
    @track maxEndDate;
    @track listOfProductItems = [];
    @track mapIndexVsProduct = {};
    @track mapToDisplayData = {};
    @track ProductDetail = {  Product : null,
                        startDate : null ,
                        endDate : null,
                        loadVolume : null,
                        shippingMode : null,
                        shippingType : null,
                        shippingConditionCode : null,
                        shippingCondition : null,
                        quantity : null,
                        poNumber : null,
                        productId : null,
                        deliveryText : null };

    @track listOfLineItem = [];
    @track structureForTableRow = { Product : null, deliveryDate: null, deliveryDay: null, Quantity: null, Tonnage: null, DeliveryText: null, PoNumber: null};
    @track listDeliveryLineItems= [];
    @track showLineItems = false;
    @track currentProduct;
    @track testTrue = false;



    @track effectiveAccountId = null;
    @track pageParam = null;
    @track sortParam = null;
    @track currencyCode;
    @track cartId;

    @api cartItemClone;
    @track cartItemOptions;
    @track cartItemAvailable;
    @api index;
    @api defaultData;
    @track lstOfDates = [];

    @track label = {
        Split_Shipment_Deliveries_Required,
        Split_Shipment_Delivery_End_Date,
        Split_Shipment_Delivery_Start_Date,
        Split_Shipment_Delivery_Text,
        Split_Shipment_Line_Item_Delivery_Date,
        Split_Shipment_Load_Volume,
        Split_Shipment_PO_Number,
        Split_Shipment_Select_Product,
        Split_Shipment_Shipping_Mode
    };




    get getTotalVolume() {
        let totalVolume = 0;
        if(this.listDeliveryLineItems) {
            for(let i of this.listDeliveryLineItems) {
                if(i.Quantity && i.Tonnage){
                    totalVolume+= parseInt(parseInt(i.Quantity)*parseInt(i.Tonnage));
                }
            }
        }
        return totalVolume;
    }

    get getProducts() {
        return this.cartItemOptions;
    }

    get productname() {
        return this.mapOfProductIdVsName[this.ProductDetail.Product];
    }

    get isProduct(){
        return this.ProductDetail.Product;
    }

    get listlength(){
        return this.listDeliveryLineItems.length;
    }

    get getTonnage() {
        return [
            { label: 'Metric Ton', value: 'Metric Ton' },
            { label: 'Ton', value: 'Ton' }
        ];
    }

    get getShippingMode() {
        return [
            { label: 'Customer Pickup', value: '99' },
            { label: 'Truck', value: "25" },
            { label: 'Oversize Truck', value: "45"},
            { label: 'Rail', value: "95"}

        ];
    }


    get isMapBlank(){
        return Object.keys(this.mapToDisplayData).length == 0 ;
    }

    getCartItems() {
        getCartItems({
            communityId: communityId,
            effectiveAccountId: this.effectiveAccountId,
            activeCartOrId: this.recordId,
            pageParam: this.pageParam,
            sortParam: this.sortParamb2bCartLineItems
        })
            .then(({ cartItems, cartSummary }) => {
                this.cartItems = cartItems;
                this.currencyCode = cartSummary.currencyIsoCode;
                this.cartId = cartSummary.cartId;

                //console.log("Cart Items--- ", this.cartItems);

                this.cartItemOptions = cartItems.map(({ cartItem }) => {
                    return {
                        value: cartItem.cartItemId,
                        label: cartItem.name
                    }
                })

                this.cartItemAvailable = cartItems.map(({ cartItem }) => {
                    this.ProductDetail.productId = cartItem.productId;
                })
            })
            .catch((error) => {
                console.log('error : ' + error);
                console.log(error);
                this.cartItems = undefined;
            });
    }





    handleChange(event){

        let mapOfProductIdVsAvailableCopy = {...this.mapOfProductIdVsAvailable};

        if(this.currentProduct == null){
            this.ProductDetail.Product = event.target.value;
            this.currentProduct = event.target.value;
            //console.log("Current Product: ", this.currentProduct);
            mapOfProductIdVsAvailableCopy[event.target.value] = false;
                let customEvent = new CustomEvent('updateselectionmap',{detail : {mapOfProductIdVsAvailableCopy: mapOfProductIdVsAvailableCopy}});
                this.dispatchEvent(customEvent);
        }

        let name = event.target.name;
        let productDetail = this.ProductDetail;

        if(event.target.name == 'Product' && event.target.value != this.currentProduct){
            //console.log("Cart Items!!!! ", this.cartItems);

            this.ProductDetail.Product = event.target.value;

            if(mapOfProductIdVsAvailableCopy[event.target.value]){
                // mapOfProductIdVsAvailableCopy[event.target.value] = false;
                // mapOfProductIdVsAvailableCopy[this.currentProduct] = true;
                // let customEvent = new CustomEvent('updateselectionmap',{detail : {mapOfProductIdVsAvailableCopy: mapOfProductIdVsAvailableCopy}});
                // this.dispatchEvent(customEvent);

                //console.log("Product: ", this.ProductDetail.Product);
                //console.log("Product Name: ", this.mapOfProductIdVsName[this.ProductDetail.Product]);
                //console.log("ID: ", this.mapOfProductNameVsId[this.mapOfProductIdVsName[this.ProductDetail.Product]]);
            
                getPONumber({ productId: this.mapOfProductNameVsId[this.mapOfProductIdVsName[this.ProductDetail.Product]] })
                    .then((result) => {
                        this.ProductDetail.poNumber = result;
                        //console.log("PO Number: ", result);
                    })
                    .catch((error) => {
                        this.error = error;
                    });

                getProduct({ productId: this.mapOfProductNameVsId[this.mapOfProductIdVsName[this.ProductDetail.Product]] })
                    .then((result) => {
                        this.ProductDetail.shippingType = result[0].Shipment_Size_Type_Label__c;
                        this.ProductDetail.shippingConditionCode = result[0].Shipping_Condition__c;
                        this.ProductDetail.shippingCondition = result[0].Shipping_Condition_Label__c;
                        this.ProductDetail.shippingMode = result[0].Ship__c;
                        this.loadVolumeLabel = 'Load Volume per ' + this.ProductDetail.shippingType;
                    })
                    .catch((error) => {
                        this.error = error;
                    });
            }else{

                event.target.value = this.currentProduct;
                this.showNotification('Product Already Selected!', 'error', 'ERROR');

            }
        }
        else if(event.target.name == 'Product') {
            this.ProductDetail.Product = event.target.value;

            //console.log("Product: ", this.ProductDetail.Product);
            //console.log("Product Name: ", this.mapOfProductIdVsName[this.ProductDetail.Product]);
            //console.log("ID: ", this.mapOfProductNameVsId[this.mapOfProductIdVsName[this.ProductDetail.Product]]);
        
            getPONumber({ productId: this.mapOfProductNameVsId[this.mapOfProductIdVsName[this.ProductDetail.Product]] })
                .then((result) => {
                    this.ProductDetail.poNumber = result;
                    //console.log("PO Number: ", result);
                })
                .catch((error) => {
                    this.error = error;
                });

            getProduct({ productId: this.mapOfProductNameVsId[this.mapOfProductIdVsName[this.ProductDetail.Product]] })
                .then((result) => {
                    this.ProductDetail.shippingType = result[0].Shipment_Size_Type_Label__c;
                    this.ProductDetail.shippingConditionCode = result[0].Shipping_Condition__c;
                    this.ProductDetail.shippingCondition = result[0].Shipping_Condition_Label__c;
                    this.ProductDetail.shippingMode = result[0].Ship__c;
                    this.loadVolumeLabel = 'Load Volume per ' + this.ProductDetail.shippingType;
                })
                .catch((error) => {
                    this.error = error;
                });
        }

        if(event.target.name == 'shippingMode') {
            this.shippingMode = event.target.value;
            this.ProductDetail.shippingMode = event.target.value;

            if(this.ProductDetail.loadVolume) {
                //handleLoadVolumeChange();
                let loadVolumeElement = this.template.querySelector(".loadVolume");
                this.ProductDetail.loadVolume = loadVolumeElement.value;

                this.handleLoadVolumeChange();    
            }
        }

        if(event.target.name == 'loadVolume') {
            //handleLoadVolumeChange();
            let loadVolumeElement = this.template.querySelector(".loadVolume");
            this.ProductDetail.loadVolume = loadVolumeElement.value;

            this.handleLoadVolumeChange();
        }

        if(event.target.name == 'startDate'){
            // let startDate = new Date((event.target.value).split('-'));
            let startDate = this.convertDate(event.target.value);
            startDate.setHours(0,0,0,0);
            let today = new Date();
            today.setHours(0,0,0,0);
            if(startDate.getTime() == today.getTime()) {
                //this.showNotification('Please call your customer rep for same day order!','warning','sticky');
                const sameDayOrderWarning = new ShowToastEvent({
                    message: Same_Day_Delivery_Warning,
                    variant: 'warning',
                    mode: 'sticky'
                });
                this.dispatchEvent(sameDayOrderWarning);
            } else {
                let maxEndDate = this.addDays(event.target.value, 90);
                this.maxEndDate = maxEndDate.getFullYear()+'-' + (parseInt(maxEndDate.getMonth())+ parseInt(1))+'-'+maxEndDate.getDate();
            }
        }

        productDetail[name] = event.target.value;
        this.ProductDetail = productDetail;
    }

    generateLoadVolumeLabel() {
        console.log('Generating Load Volume Label...');
        switch(this.ProductDetail.shippingMode) {
            case '99':
                this.loadVolumeLabel = "Load Volume per Customer Truck";
                break;
            case '25':
                this.loadVolumeLabel = "Load Volume per Truck (max 25)";
                break;
            case '45':
                this.loadVolumeLabel = "Load Volume per Oversize Truck (max 50)";
                break;
            case '95':
                this.loadVolumeLabel = "Load Volume per Rail Car (max 95)";
                break;
        }
    }

    handleLoadVolumeChange() {
        let loadVolumeElement = this.template.querySelector(".loadVolume");
        this.ProductDetail.loadVolume = loadVolumeElement.value;

            console.log("Load Volume: ", this.ProductDetail.loadVolume);

            switch(this.ProductDetail.shippingMode) {
                case '99':
                    if(loadVolumeElement.value > 50) {
                        loadVolumeElement.setCustomValidity("Customer PU - Truck Volume can't exceed 50");
                    } else if(loadVolumeElement.value < 1) {
                        loadVolumeElement.setCustomValidity("Customer PU - Truck Volume must be at least 1");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '25':
                    if(loadVolumeElement.value > 25) {
                        loadVolumeElement.setCustomValidity("Truck Volume can't exceed 25");
                    } else if(loadVolumeElement.value < 5) {
                        loadVolumeElement.setCustomValidity("Truck Volume must be at least 5");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '50':
                    if(loadVolumeElement.value > 50) {
                        loadVolumeElement.setCustomValidity("Oversized Truck Volume can't exceed 50");
                    } else if(loadVolumeElement.value < 1) {
                        loadVolumeElement.setCustomValidity("Oversized Truck Volume must be at least 1");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '95':
                    if(loadVolumeElement.value > 95) {
                        loadVolumeElement.setCustomValidity("Rail Volume can't exceed 95");
                    } else if(loadVolumeElement.value < 1) {
                        loadVolumeElement.setCustomValidity("Rail Volume must be at least 1");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '36':
                    if(loadVolumeElement.value > 25) {
                        loadVolumeElement.setCustomValidity("Pneumatic Trailer Volume can't exceed 25");
                    } else if(loadVolumeElement.value < 24) {
                        loadVolumeElement.setCustomValidity("Pneumatic Trailer Volume must be at least 24");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '34':
                    if(loadVolumeElement.value > 24) {
                        loadVolumeElement.setCustomValidity("Van Trailer Volume can't exceed 24");
                    } else if(loadVolumeElement.value < 18) {
                        loadVolumeElement.setCustomValidity("Van Trailer Volume must be at least 18");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '33':
                    if(loadVolumeElement.value > 45) {
                        loadVolumeElement.setCustomValidity("Flat Bed Trailer Volume can't exceed 45");
                    } else if(loadVolumeElement.value < 18) {
                        loadVolumeElement.setCustomValidity("Flat Bed Trailer Volume must be at least 18");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '35':
                    if(loadVolumeElement.value > 35) {
                        loadVolumeElement.setCustomValidity("Pneu Trl/Hyd Lime Volume can't exceed 35");
                    } else if(loadVolumeElement.value < 20) {
                        loadVolumeElement.setCustomValidity("Pneu Trl/Hyd Lime Volume must be at least 20");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '37':
                    if(loadVolumeElement.value > 50) {
                        loadVolumeElement.setCustomValidity("Oversize TLR Dump Volume can't exceed 50");
                    } else if(loadVolumeElement.value < 30) {
                        loadVolumeElement.setCustomValidity("Oversize TLR Dump Volume must be at least 30");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '30':
                    if(loadVolumeElement.value > 25) {
                        loadVolumeElement.setCustomValidity("Dump Trailer Volume can't exceed 25");
                    } else if(loadVolumeElement.value < 23) {
                        loadVolumeElement.setCustomValidity("Dump Trailer Volume must be at least 23");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '38':
                    if(loadVolumeElement.value > 50) {
                        loadVolumeElement.setCustomValidity("Oversize TLR Pneu Volume can't exceed 50");
                    } else if(loadVolumeElement.value < 30) {
                        loadVolumeElement.setCustomValidity("Oversize TLR Pneu Volume must be at least 30");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '32':
                    if(loadVolumeElement.value > 50) {
                        loadVolumeElement.setCustomValidity("Multi TLR Pneu Volume can't exceed 50");
                    } else if(loadVolumeElement.value < 30) {
                        loadVolumeElement.setCustomValidity("Multi TLR Pneu Volume must be at least 30");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '55':
                    if(loadVolumeElement.value > 100) {
                        loadVolumeElement.setCustomValidity("Railcar Cvrd Hpr PVT Volume can't exceed 100");
                    } else if(loadVolumeElement.value < 90) {
                        loadVolumeElement.setCustomValidity("Railcar Cvrd Hpr PVT Volume must be at least 90");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '98':
                    if(loadVolumeElement.value > 100) {
                        loadVolumeElement.setCustomValidity("Customer PU - Rail Volume can't exceed 100");
                    } else if(loadVolumeElement.value < 90) {
                        loadVolumeElement.setCustomValidity("Customer PU - Rail Volume must be at least 90");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '51':
                    if(loadVolumeElement.value > 100) {
                        loadVolumeElement.setCustomValidity("Railcar Cvrd Hpr R/R Volume can't exceed 100");
                    } else if(loadVolumeElement.value < 90) {
                        loadVolumeElement.setCustomValidity("Railcar Cvrd Hpr R/R Volume must be at least 90");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '10':
                    if(loadVolumeElement.value > 1600) {
                        loadVolumeElement.setCustomValidity("Covered Rake Volume can't exceed 1600");
                    } else if(loadVolumeElement.value < 1400) {
                        loadVolumeElement.setCustomValidity("Covered Rake Volume must be at least 1400");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '11':
                    if(loadVolumeElement.value > 1600) {
                        loadVolumeElement.setCustomValidity("Covered Box Volume can't exceed 1600");
                    } else if(loadVolumeElement.value < 1400) {
                        loadVolumeElement.setCustomValidity("Covered Box Volume must be at least 1400");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '15':
                    if(loadVolumeElement.value > 1600) {
                        loadVolumeElement.setCustomValidity("Open Hopper Rake Volume can't exceed 1600");
                    } else if(loadVolumeElement.value < 1400) {
                        loadVolumeElement.setCustomValidity("Open Hopper Rake Volume must be at least 1400");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
                case '97':
                    if(loadVolumeElement.value > 1600) {
                        loadVolumeElement.setCustomValidity("Customer Barge Volume can't exceed 1600");
                    } else if(loadVolumeElement.value < 5) {
                        loadVolumeElement.setCustomValidity("Customer Barge Volume must be at least 1400");
                    } else {
                        loadVolumeElement.setCustomValidity("");
                    }
                    loadVolumeElement.reportValidity();
                    break;
            }

            return true;
    }

    handleProductChange(event) {
        this.ProductDetail.Product = event.target.value;
        //console.log("Cart Item ID- ", this.mapOfProductNameVsId[this.ProductDetail.Product]);
    }

    connectedCallback(){
        let defaultObject = JSON.parse(this.defaultData);
        if(defaultObject.defaultShipmentType == "Truck"){
            this.ProductDetail.shippingMode = "25";
        }else if(defaultObject.defaultShipmentType == "Oversize Truck"){
            this.ProductDetail.shippingMode = "45";
        }else if(defaultObject.defaultShipmentType == "Rail"){
            this.ProductDetail.shippingMode = "95";
        }
        //this.ProductDetail.poNumber = defaultObject.defaultPoNumber;

        this.ProductDetail.loadVolume = defaultObject.defaultLoadVolume;
        this.ProductDetail.deliveryText = defaultObject.defaultDeliveryText;
        if(this.mapOfIndexVsProductDetail[this.index]) {
            this.ProductDetail = {...this.mapOfIndexVsProductDetail[this.index].ProductDetail};
            this.listOfLineItem = {...this.mapOfIndexVsProductDetail[this.index].listOfLineItem}
        }
        this.cartItemOptions = JSON.parse(JSON.stringify(this.cartItemClone));
        let today = new Date();
        today.setDate(today.getDate() + 1);
        this.today = today.getFullYear()+'-' + (parseInt(today.getMonth())+ parseInt(1))+'-'+today.getDate();
        let maxDate = new Date();
        maxDate.setDate(today.getDate() + 90);
        this.maxDate = maxDate.getFullYear()+'-' + (parseInt(maxDate.getMonth())+ parseInt(1))+'-'+maxDate.getDate();
    }

    handleMeasureChange(event) {
        this.selectedMeasure = event.target.value;
    }

    handleselectedStartDateChange(event) {
        //console.log('handle selected start date change', event.target.value);
        this.selectedStartDate = event.target.value;
        let maxEndDate = this.addDays(this.selectedStartDate, 90);
        this.maxEndDate = maxEndDate.getFullYear()+'-' + (parseInt(maxEndDate.getMonth())+ parseInt(1))+'-'+maxEndDate.getDate();
        //console.log('setting start date');
        this.fireEvent();
    }

    handleselectedEndDateChange(event){
        this.selectedEndDate = event.target.value;
        this.fireEvent();
    }

    handleNumberOfRecurrenceChange(event) {
        this.selectedNumberOfRecurring = event.target.value;
        this.fireEvent();
    }

    handleShippingModeChange(event) {
        this.selectedShippingMode = event.target.value;
        this.fireEvent();
    }

    handleQuantityChange(event) {
        this.selectedQuantity = event.target.value;
        this.fireEvent();
    }

    handlePoNumberChange(event) {
        this.enteredPoNumber = event.target.value;
        this.fireEvent();
    }

    handleDeliveryTextChange(event) {
        this.enteredDeliveryText = event.target.value;
        this.fireEvent();
    }

    handleDeliveryTextChangeOfLineItem(event){
        let index = event.target.name;
        let lineItemForThisIndex = {...this.listDeliveryLineItems[index]};
        lineItemForThisIndex.DeliveryText = event.target.value;
        this.listDeliveryLineItems[index] = lineItemForThisIndex;
        this.fireEvent();
    }

    handlePoNumberPerLineItemChange(event){
        let index = event.target.name;
        let lineItemForThisIndex = {...this.listDeliveryLineItems[index]};
        lineItemForThisIndex.PoNumber = event.target.value;
        this.listDeliveryLineItems[index] = lineItemForThisIndex;
        this.fireEvent();
    }

    handleDeliveryDateChangeOfLineItem(event){
        let index = event.target.name;
        let lineItemForThisIndex = {...this.listDeliveryLineItems[index]};
        let previousDeliveryDate = lineItemForThisIndex.deliveryDate;
        let endDate = new Date((this.maxEndDate).split('-'));
        endDate.setHours(0,0,0,0);
        let startDate = new Date((event.target.value).split('-'));
        startDate.setHours(0,0,0,0);
        let today = new Date();
        today.setHours(0,0,0,0);

        if(startDate.getTime() == today.getTime()) {
            //this.showNotification('Please call your customer rep for same day order!','warning','sticky');
            const sameDayOrderWarning = new ShowToastEvent({
                message: Same_Day_Delivery_Warning,
                variant: 'warning',
                mode: 'sticky'
            });
            this.dispatchEvent(sameDayOrderWarning);
            event.target.value = lineItemForThisIndex.deliveryDate;
        }else if(startDate.getTime() > endDate.getTime() || startDate.getTime() < today.getTime()) {
            event.target.value = lineItemForThisIndex.deliveryDate;
        } else if(this.lstOfDates.includes(event.target.value)){
            this.showNotification('Duplicate Date!','error', 'ERROR');
            event.target.value = lineItemForThisIndex.deliveryDate;
        }else{
            if(previousDeliveryDate){
                this.lstOfDates.splice(this.lstOfDates.indexOf(previousDeliveryDate));
            }
            lineItemForThisIndex.deliveryDate = event.target.value;
            let deliveryDate = this.addDays(event.target.value, 0);
            let deliveryDay = deliveryDate.getDay();
            switch(deliveryDay) {
                case 0:
                    lineItemForThisIndex.deliveryDay = 'Sunday';
                    break;
                case 1:
                    lineItemForThisIndex.deliveryDay = 'Monday';
                    break;
                case 2:
                    lineItemForThisIndex.deliveryDay = 'Tuesday';
                    break;
                case 3:
                    lineItemForThisIndex.deliveryDay = 'Wednesday';
                    break;
                case 4:
                    lineItemForThisIndex.deliveryDay = 'Thursday';
                    break;
                case 5:
                    lineItemForThisIndex.deliveryDay = 'Friday';
                    break;
                case 6:
                    lineItemForThisIndex.deliveryDay = 'Saturday';
                    break;
            }
            //console.log("New Day: ", lineItemForThisIndex.deliveryDate.getDay());
            this.lstOfDates.push(lineItemForThisIndex.deliveryDate);
            this.listDeliveryLineItems[index] = lineItemForThisIndex;
            this.fireEvent();
        }
    }

    handleGenerateLineItems(event) {
        //console.log('detecting device: ', navigator.userAgent, navigator.vendor);
        //console.log('generating line items');
        try{
            let isValid = this.validityCheck();
            //console.log('validity:', isValid);
        let enddate ;
        if(isValid) {

            this.showLineItems = false;
            this.listDeliveryLineItems = [];
            if(this.ProductDetail.endDate){
                enddate = this.ProductDetail.endDate;
            }else{
                enddate = this.ProductDetail.startDate;
            }
            //console.log('product detail:', JSON.parse(JSON.stringify(this.ProductDetail)));
            //console.log('enddate: ', enddate);
            //console.log('startdate: ', this.ProductDetail.startDate);

            let date2 = this.convertDate(enddate);
            //console.log('date2', date2);

            let date1 = this.convertDate(this.ProductDetail.startDate);
            //console.log('date1: ', date1);

            /*let measureNumber = 1;
            if(this.ProductDetail.unitOfMeasure == 'Metric Ton'){
                measureNumber = 0.907;
            }*/
            var Difference_In_Time = date2.getTime() - date1.getTime();
            //console.log('Difference_In_Time: :', Difference_In_Time);
            var Difference_In_Days = (parseInt(Difference_In_Time / (1000 * 3600 * 24)) + parseInt(1));
            //console.log('Difference_In_Days: :', Difference_In_Days);
            let numberOfRecursion = parseInt(Difference_In_Days);
            for(let i=0; i<numberOfRecursion; i++) {
                let structure = {...this.structureForTableRow};
                structure.Product = this.ProductDetail.Product;
                let deliveryDate = this.addDays(this.ProductDetail.startDate, i);
                let deliveryDay = deliveryDate.getDay();
                structure.deliveryDate = deliveryDate.getFullYear()+'-' + (parseInt(deliveryDate.getMonth())+ parseInt(1))+'-'+deliveryDate.getDate();
                switch(deliveryDay) {
                    case 0:
                        structure.deliveryDay = 'Sunday';
                        break;
                    case 1:
                        structure.deliveryDay = 'Monday';
                        break;
                    case 2:
                        structure.deliveryDay = 'Tuesday';
                        break;
                    case 3:
                        structure.deliveryDay = 'Wednesday';
                        break;
                    case 4:
                        structure.deliveryDay = 'Thursday';
                        break;
                    case 5:
                        structure.deliveryDay = 'Friday';
                        break;
                    case 6:
                        structure.deliveryDay = 'Saturday';
                        break;
                }
                structure.Quantity = this.ProductDetail.quantity;
                structure.Tonnage = this.ProductDetail.loadVolume;
                structure.DeliveryText = this.ProductDetail.deliveryText;
                structure.PoNumber = this.ProductDetail.poNumber;
                structure.index = i;
                // let structureToCompare = {...structure};
                //console.log('structure: ');
                //console.log(structure);
                let structureToCompare = Object.assign({}, structure);
                //console.log('structure to compare: ');
                //console.log(structureToCompare);
                structureToCompare.deliveryDate = deliveryDate.getFullYear()+'-' + this.addZeroInMonthDays(parseInt(deliveryDate.getMonth()) + parseInt(1))+'-'+this.addZeroInMonthDays(deliveryDate.getDate());
                structure.deliveryDate = structureToCompare.deliveryDate;
                this.lstOfDates.push(structureToCompare.deliveryDate);
                this.listDeliveryLineItems.push(structure);

            }

            this.showLineItems = true;
            this.fireEvent();

            // mapOfProductIdVsAvailableCopy[this.ProductDetail.Product] = false;
            // //mapOfProductIdVsAvailableCopy[this.currentProduct] = true;
            // let customEvent = new CustomEvent('updateselectionmap',{detail : {mapOfProductIdVsAvailableCopy: mapOfProductIdVsAvailableCopy}});
            // this.dispatchEvent(customEvent);

            if(this.lineItemsGenerated != true) {
                this.lineItemsGenerated = true;
                let customEvent = new CustomEvent('updatesubmitbutton');
                this.dispatchEvent(customEvent);

                // Activate add products button
                let activateButtonEvent = new CustomEvent('activateaddproductsbutton');
                this.dispatchEvent(activateButtonEvent);
            }
        }

        }catch(err){
            //console.log('eror', err);
        }
    }

    addZeroInMonthDays(dataToChange){

       // dataToChange = {...dataToChange};
        if(dataToChange && dataToChange.toString().length == 1){
            dataToChange = '0' + dataToChange ;
        }
        return dataToChange;
    }

    handleDeleteProduct() {
        let customEvent = new CustomEvent('deleteproduct',{detail : {index : this.index}});
        this.dispatchEvent(customEvent);
    }

    fireEvent(){
        let customEvent = new CustomEvent('updateproductdetails',{detail : {Product:{ProductDetail: this.ProductDetail,
                                                                                    listOfLineItem : this.listDeliveryLineItems},
                                                                            index : this.index}});
            this.dispatchEvent(customEvent);
    }

    addLineItems(){
        this.showLineItems = false;
        let structure = {...this.structureForTableRow};
        structure.Product = this.selectedProduct;
        structure.Quantity = 0;
        structure.Tonnage = this.ProductDetail.loadVolume;
        structure.DeliveryText = this.enteredDeliveryText;
        structure.PoNumber = this.enteredPoNumber;
        structure.index = this.listDeliveryLineItems.length;

        this.listDeliveryLineItems.push(structure);
        this.showLineItems = true;

    }

    validityCheck(){
        let validity;
            let elements = Array.from(this.template.querySelectorAll('[data-id =checkValidity]'));
                if(elements!= undefined && elements!=null) {
                    validity =  elements.reduce((validSoFar,inputcmp) => {
                        inputcmp.reportValidity();
                        return validSoFar && inputcmp.checkValidity();
                    },true );
                }
        return validity;
    }

    validityLineItemCheck(){
        let validity;
        let validityDeliveryLineItem;
            let elements = Array.from(this.template.querySelectorAll('[data-id =checkLineItemValidity]'));
                if(elements!= undefined &&
                    elements!=null) {
                    validity =  elements.reduce((validSoFar,inputcmp) => {
                        inputcmp.reportValidity();
                        return validSoFar && inputcmp.checkValidity();
                    },true );
                }
            let deliveryDateelements = Array.from(this.template.querySelectorAll('[data-validity =checkDeliveryDateValidity]'));
            if(deliveryDateelements!= undefined &&
                deliveryDateelements!=null) {

                    validityDeliveryLineItem =  deliveryDateelements.reduce((validSoFar,inputcmp) => {
                    if(!inputcmp.value){
                        return validSoFar && false;
                    }else{
                        return validSoFar && true
                    }
                },true );
            }
        return validity && validityDeliveryLineItem;
    }


    @api
    combinedValidityCheck(){
        return this.validityCheck() && this.validityLineItemCheck();
    }

    convertDate(dateString) {
        let dateSplit = dateString.split('-');

        let dateObject = {
            year: parseInt(dateSplit[0]),
            month: parseInt(dateSplit[1]) - 1,
            day: parseInt(dateSplit[2])
        };

        return new Date(dateObject.year, dateObject.month, dateObject.day);
    }

    addDays(date, days) {
       // let splittedDate = (date).split('-');
        var result = this.convertDate(date);
        result.setDate(result.getDate() + days);
        return result;
    }


    handleLineItemQuantityChange(event) {
        this.showLineItems = false;
        /*let measureNumber = 1;
        if(this.ProductDetail.unitOfMeasure == 'Metric Ton'){
            measureNumber = 0.907;
        }*/
        let selectedQuantity = event.target.value;
        let index = event.target.name;
        /*let tonnageValue ;
        if(!selectedQuantity){
            tonnageValue = 0;
        }else{
            tonnageValue = parseInt(selectedQuantity) * parseInt(this.ProductDetail.shippingMode)*measureNumber;
        }*/
        let lineItemForThisIndex = {...this.listDeliveryLineItems[index]};
        lineItemForThisIndex.Tonnage = this.ProductDetail.loadVolume ;
        lineItemForThisIndex.Quantity = selectedQuantity;
        this.listDeliveryLineItems[index] = lineItemForThisIndex;
        this.showLineItems = true;
        this.fireEvent();
    }

    deleteLineItem(event){
        this.showLineItems = false;
        let index = event.target.name;

        let structureToCompare = {...this.listDeliveryLineItems[index]};

        let dataToDelete = structureToCompare.deliveryDate;
        if(dataToDelete){
            let splitData = dataToDelete.split('-');

            structureToCompare.deliveryDate = splitData[0]+'-' + this.addZeroInMonthDays(splitData[1]) +'-'+ this.addZeroInMonthDays(splitData[2]);
            if(this.lstOfDates.includes(structureToCompare.deliveryDate)){
                this.lstOfDates.splice(this.lstOfDates.indexOf(structureToCompare.deliveryDate),1);
            }
        }

        this.listDeliveryLineItems.splice(index, 1);
        this.showLineItems = true;
        this.fireEvent();
    }

    getDeliveryDayFromDate(deliveryDate) {

    }

    @api
    showNotification(message, variant, title) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

}
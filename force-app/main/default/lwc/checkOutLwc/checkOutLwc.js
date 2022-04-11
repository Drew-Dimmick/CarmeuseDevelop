import { LightningElement, api, track } from 'lwc';
import communityId from '@salesforce/community/Id';
import getCartItems from '@salesforce/apex/B2BCartController.getCartItems';
import splitShipments from '@salesforce/apex/B2BSplitShipment.splitShipments';
import splitShipmentsDefaults from '@salesforce/apex/B2BSplitShipment.getSplitShipmentDefaults';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

var productsAdded = 1;
var numProducts = 0;
var lineItemsGenerated = 0;

export default class CheckOutLwc extends LightningElement {

    @api recordId;
    @api mapOfProductIdVsAvailable = {};
    @track isDisabled = false;
    @track listOfProductItems = [];
    @track show = true;
    @track mapOfProductIdVsLabel = {};
    @track today;
    @track effectiveAccountId = null;
    @track pageParam = null;
    @track sortParam = null;
    @track currencyCode;
    @track cartId;
    @track cartItemOptions;
    @track cartItemAvailable;
    @track mapOfProductIdVsName = {};
    @track mapOfProductNameVsId = {};
    @track cartItems;
    @track mapOfIndexVsProductDetail = {};
    @track sortParamb2bCartLineItems;
    @track defaultData ;


    connectedCallback() {
        this.getCartItems();
        splitShipmentsDefaults({cartId: this.recordId})
        .then(result => {
            this.defaultData = result;

        })
        .catch(error => {
           console.log(error);
        })
    }

    addLineItems(event){
        productsAdded++;
        //console.log("Hide add button");
        let addButton = this.template.querySelector(".addProducts");
        addButton.disabled = true;
        let indexToPush = this.listOfProductItems.length;
        this.listOfProductItems.push(indexToPush);
    }

    get showAddProductButtons(){

        return this.cartItemAvailable != null &&
                this.cartItemAvailable != undefined &&
                this.cartItemAvailable.length > 0 &&
                this.cartItemOptions != null &&
                this.cartItemOptions != undefined &&
                this.cartItemOptions.length > 1 ;
    }

    updateSubmitButton() {
        lineItemsGenerated++;

        if(lineItemsGenerated >= numProducts) {
            let submitButton = this.template.querySelector(".submit");
            submitButton.disabled = false;
        } else {
            //console.log("Still need to generate all line items");
        }
    }

    updateAddProductsButton() {
        if(productsAdded < numProducts) {
            //console.log("Hide add button");
            let addButton = this.template.querySelector(".addProducts");
            addButton.disabled = false;

        //     let indexToPush = this.listOfProductItems.length;
        //     this.listOfProductItems.push(indexToPush);
        //     if(productsAdded >= numProducts) {
        //         let addButton = this.template.querySelector(".addProducts");
        //         addButton.disabled = true;
        //     }
        //     console.log(productsAdded);
        // } else {
        //     console.log("Hide add button");
        //     let addButton = this.template.querySelector(".addProducts");
        //     addButton.disabled = true;
        }
    }

    /**get getCartItemOptions() {
        return [
            { label: 'None', value: '' },
            { label: 'Truck', value: "25" },
            { label: 'Oversize Truck', value: "45"},
            { label: 'Rail', value: "95"}

        ];
    }**/

    handleSubmit(){
        let elements = Array.from(this.template.querySelectorAll('c-split-shipment-product-details'));
        let isValid = true;
        if(elements){
            for(let elementInstance of elements){
                isValid = isValid && elementInstance.combinedValidityCheck();
            }
        }
        if(isValid){
            if(!this.toCheckAllProductsSelected()){
                elements[0].showNotification('Please generate line items for all products', 'error', 'ERROR');
            }else{
                let completeProductsData = {...this.mapOfIndexVsProductDetail};
                let mapAllProducts  = {};
                for(let i of Object.keys(completeProductsData)){
                    mapAllProducts[completeProductsData[i].ProductDetail.Product] = completeProductsData[i];
                }
                //Todo send in payload
                //console.log(JSON.parse(JSON.stringify(mapAllProducts)));
                //console.log(JSON.stringify(mapAllProducts));

                // added to send payload KH 3/23 8:30PST
                splitShipments({
                    cartId: this.cartId,
                    payload: JSON.stringify(mapAllProducts)
                }).then(() => {
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                }).catch(error => {
                    console.error(error);
                });
            }

        }else{
            elements[0].showNotification('Please enter valid inputs', 'error', 'ERROR');
        }

    }

    toCheckAllProductsSelected(){
        if(Object.values(this.mapOfProductIdVsAvailable).includes(true)){
            return false;
        }else{
            return true;
        }
    }

    getCartItems() {
       /* this.cartItemOptions = [
            { label: 'None', value: '' },
            { label: 'Truck', value: "25" },
            { label: 'Oversize Truck', value: "45"},
            { label: 'Rail', value: "95"}

        ];*/

        // console.log("Community Id: ", communityId);
        // console.log("Effective Account ID: ", this.effectiveAccountId);
        // console.log("Active Cart or ID: ", this.recordId);
        // console.log("Page Param: ", this.pageParam);
        // console.log("Sort Param: ", this.sortParamb2bCartLineItems);

        getCartItems({
            communityId: communityId,
            effectiveAccountId: this.effectiveAccountId,
            activeCartOrId: this.recordId,
            pageParam: this.pageParam,
            sortParam: this.sortParamb2bCartLineItems
        })
            .then(({ cartItems, cartSummary }) => {
                //console.log('cartItems : ' + JSON.stringify(cartItems));
                this.cartItems = cartItems;
                this.currencyCode = cartSummary.currencyIsoCode;
                this.cartId = cartSummary.cartId;

                this.cartItemAvailable = cartItems.map(({ cartItem }) => {
                    var tempName = cartItem.name;
                    //console.log("Before replace: ", tempName);
                    tempName = tempName.replaceAll("&quot;", "\"");
                    cartItem.name = tempName;
                    cartItem.productDetails.name = tempName;
                    //console.log("After replace: ", tempName);
                    this.mapOfProductIdVsAvailable[cartItem.cartItemId] = true;
                    this.mapOfProductIdVsLabel[cartItem.cartItemId] = cartItem.name;
                    return {
                        value: cartItem.cartItemId,
                        label: cartItem.name
                    }
                })
                this.cartItemOptions = cartItems.map(({ cartItem }) => {
                    var tempName = cartItem.name;
                    //console.log("Before replace: ", tempName);
                    tempName = tempName.replaceAll("&quot;", "\"");
                    cartItem.name = tempName;
                    cartItem.productDetails.name = tempName;
                    //console.log("After replace: ", tempName);
                    this.mapOfProductIdVsName[cartItem.cartItemId] = cartItem.name;
                    this.mapOfProductNameVsId[cartItem.name] = cartItem.productId;
                    //console.log("LIST: ", this.mapOfProductNameVsId);
                    //console.log("ID: ", this.mapOfProductNameVsId['Dolo QL #6 X 0" Bulk']);
                    //console.log("CART ITEM ID", cartItem.productId);
                    //console.log("CART ITEMS OPTIONS", cartItem);
                    numProducts++;
                    //console.log(numProducts);
                    return {
                        value: cartItem.cartItemId,
                        label: cartItem.name
                    }
                })


                this.listOfProductItems.push(0);

            })
            .catch((error) => {
                console.log('error : ' + error);
                console.log(error);
                this.cartItems = undefined;
            });

    }

    handleDeleteProduct(event){
        this.show = false;
        const details = event.detail;
        let productIndexToDelete = details.index;
        let product = this.mapOfIndexVsProductDetail[productIndexToDelete].ProductDetail.Product;
        this.mapOfProductIdVsAvailable[product] = true;

        if(this.cartItemAvailable) {
            this.cartItemAvailable.push({
                                            value: product,
                                            label: this.mapOfProductIdVsLabel[product]
                                        })
        }
        delete this.mapOfIndexVsProductDetail[productIndexToDelete];



        if(this.listOfProductItems) {
            this.listOfProductItems.splice(this.listOfProductItems.indexOf(productIndexToDelete), 1);
        }
       this.show = true;
       if(this.listOfProductItems.length == 0) {
            setTimeout(() => {
                this.listOfProductItems = [0];
            }, 500);
        }

    }

    handleUpdateSelectionMap(event) {
        const details = event.detail;
        this.mapOfProductIdVsAvailable = details.mapOfProductIdVsAvailableCopy;
    }

    handleProductDetailsAddition(event){
        const details = event.detail;
        this.mapOfIndexVsProductDetail[details.index] = details.Product;
        this.cartItemAvailable = this.cartItemAvailable.filter(cartData => cartData.value != details.Product.ProductDetail.Product);
    }


}
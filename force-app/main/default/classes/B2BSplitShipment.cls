public without sharing class B2BSplitShipment {
	@AuraEnabled
	public static String getSplitShipmentDefaults(Id cartId){
		try {
			SplitShipmentDefaults defaults = new SplitShipmentDefaults();
			// Contact loggedInUserContact = OrderUtils.getLoggedInCommunityUserContact();
			// Account associatedAccount = loggedInUserContact.Account;

			// defaults.defaultDeliveryText = associatedAccount.Default_Delivery_Text__c;
			// defaults.defaultLoadVolume = associatedAccount.Default_Load_Volume__c;
			// defaults.defaultPoNumber = associatedAccount.DefaultPONumber__c;
			// defaults.defaultShipmentType = associatedAccount.Default_Shipment_Type__c;
			Account effectiveAccount = OrderUtils.getEffectiveAccount(cartId);
			defaults.defaultDeliveryText = effectiveAccount.Default_Delivery_Text__c;
			defaults.defaultLoadVolume = effectiveAccount.Default_Load_Volume__c;
			defaults.defaultPoNumber = effectiveAccount.DefaultPONumber__c;
			defaults.defaultShipmentType = effectiveAccount.Default_Shipment_Type__c;

			return JSON.serialize(defaults);
		} catch (Exception e) {
			System.debug(e);
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void splitShipments(Id cartId, String payload) {
		Map<Id, CartItem> existingCartItemsMap = new Map<Id, CartItem>(OrderUtils.getCartItemsByCartId(cartId));
		Contact loggedInUserContact;
		Account effectiveAccount;
		if(!Test.isRunningTest()) {
			//loggedInUserContact = OrderUtils.getLoggedInCommunityUserContact();
			effectiveAccount = OrderUtils.getEffectiveAccount(cartId);
		}
		else {
			loggedInUserContact = [SELECT FIELDS(STANDARD), Account.AccountExternalNumber__c, Account.IsHold__c,
					Account.Default_Delivery_Text__c, Account.Default_Load_Volume__c, 
					Account.DefaultPONumber__c, Account.Default_Shipment_Type__c, Account.Name
				FROM Contact
				WHERE Name = 'Test Contact'
				LIMIT 1
			];

			effectiveAccount = new Account();
			effectiveAccount.AccountExternalNumber__c =  loggedInUserContact.Account.AccountExternalNumber__c; 
			effectiveAccount.IsHold__c =  loggedInUserContact.Account.IsHold__c; 
			effectiveAccount.Default_Delivery_Text__c =  loggedInUserContact.Account.Default_Delivery_Text__c; 
			effectiveAccount.Default_Load_Volume__c =  loggedInUserContact.Account.Default_Load_Volume__c; 
			effectiveAccount.DefaultPONumber__c =  loggedInUserContact.Account.DefaultPONumber__c; 
			effectiveAccount.Default_Shipment_Type__c =  loggedInUserContact.Account.Default_Shipment_Type__c; 
			effectiveAccount.Name =  loggedInUserContact.Account.Name; 
			effectiveAccount.Id = loggedInUserContact.Account.Id; 
		
		}

		System.debug('---- logged in user contact ----');
		//System.debug(loggedInUserContact);
		System.debug(effectiveAccount);

		String formattedPayload = payload;

		for (Id cartItemId : existingCartItemsMap.keySet()) {
			String idString = '"' + String.valueOf(cartItemId) + '":';
			formattedPayload = formattedPayload.replace(idString, '');
		}

		String payloadReplaced = formattedPayload.replace('"Product"', '"CartItemId"');
		formattedPayload = '[' + payloadReplaced.substring(1, payloadReplaced.length() - 1) + ']';

		System.debug('----- formatted payload -------');
		System.debug(formattedPayload);

		List<ProductDetail> parsedProductDetails =
				(List<ProductDetail>) JSON.deserialize(formattedPayload,
						List<ProductDetail>.class);

		System.debug('----- parsed product details -------');
		System.debug(parsedProductDetails);

		List<ProductDetail> details = parsedProductDetails;

		List<CartDeliveryGroup> existingCartDeliveryGroups = OrderUtils.getCartDeliveryGroupsByCartId(cartId);
		Boolean defaultCartDeliveryGroupUpdated = false;

		OrderDeliveryMethod defaultDeliveryMethod = [SELECT Id FROM OrderDeliveryMethod WHERE IsActive = true LIMIT 1];

		Set<Id> relevantProducts = new Set<Id>();
		for (ProductDetail detail : details) {
			CartItem existingCartItem = existingCartItemsMap.get(detail.ProductDetail.CartItemId);
			relevantProducts.add(existingCartItem.Product2Id);
		}

		Map<Id, Product2> productMap = new Map<Id, Product2>(
				OrderUtils.getProductsByIds(
						new List<Id>(relevantProducts)
				)
		);

		//List<PricebookEntry> pricebookEntries = OrderUtils.getPricebookEntriesByProductIdsAndAccount(new List<Id>(productMap.keySet()), loggedInUserContact.Account);

		set<Id> pricebookIds = OrderUtils.getPricebookIds(effectiveAccount.Id);
		List<PricebookEntry> pricebookEntries = OrderUtils.getPricebookEntriesByProductIdsAndAccount(productMap.keySet(), pricebookIds);
		Map<Id, PricebookEntry> productIdToPricebookEntry = new Map<Id, PricebookEntry>();
		for (PricebookEntry entry : pricebookEntries) {
			productIdToPricebookEntry.put(entry.Product2Id, entry);
		}

		System.debug('---- product Id to pricebook entry ---');
		System.debug(productIdToPricebookEntry);

		List<ContactPointAddress> relatedAddresses = [
			SELECT Id, Address, AddressType
			FROM ContactPointAddress
			//WHERE ParentId = :loggedInUserContact.AccountId
			WHERE ParentId = :effectiveAccount.Id
			AND IsDefault = true
		];

		Id billingAddressId;
		Id shippingAddressId;
		for (ContactPointAddress add : relatedAddresses) {
			if(add.AddressType == 'Billing') {
				billingAddressId = add.Id;
			}
			else if (add.AddressType == 'Shipping') {
				shippingAddressId = add.Id;
			}
		}

		Map<Id, List<CartDeliveryGroup>> productIdToNewDeliveryGroups = new Map<Id, List<CartDeliveryGroup>>();

		for (ProductDetail detail : details) {
			CartItem existingCartItem = existingCartItemsMap.get(detail.ProductDetail.CartItemId);
			Id productId = existingCartItem.Product2Id;

			for (SplitShipmentLineItem lineItem : detail.listOfLineItem) {
				String splitShipmentId = String.valueOf(Math.round(Math.random() * 10000));
				for (Integer i = 0; i < lineItem.Quantity; i++) {

					if(!defaultCartDeliveryGroupUpdated) {
						existingCartDeliveryGroups[0].Quantity__c = 1;
						existingCartDeliveryGroups[0].DeliveryText__c = lineItem.DeliveryText;
						existingCartDeliveryGroups[0].ShippingInstructions = lineItem.DeliveryText;

						Date deliveryDate = Date.valueOf(lineItem.deliveryDate);

						String quoteNumber;

						for(PricebookEntry pbEntry : pricebookEntries) {
							if(pbEntry.Product2Id == existingCartItem.Product2Id) {
								Date validToDate = Date.newInstance(pbEntry.ValidTo__c.year() ,pbEntry.ValidTo__c.month(), pbEntry.ValidTo__c.day());
								Date validFromDate = Date.newInstance(pbEntry.ValidFrom__c.year() ,pbEntry.ValidFrom__c.month(), pbEntry.ValidFrom__c.day());
								if(deliverydate <= validToDate && deliveryDate >= validFromDate) {
									quoteNumber = pbEntry.Quote_Number__c;
								}
							}
						}

						//existingCartDeliveryGroups[0].Quote_Number__c = productIdToPricebookEntry.get(existingCartItem.Product2Id)?.Quote_Number__c;
						existingCartDeliveryGroups[0].Quote_Number__c = quoteNumber;
						existingCartDeliveryGroups[0].AccountExternalNumber__c = effectiveAccount.AccountExternalNumber__c;

						existingCartDeliveryGroups[0].IsHold__c = effectiveAccount.IsHold__c;
						existingCartDeliveryGroups[0].MaterialNumber__c = productMap.get(existingCartItem.Product2Id)?.MaterialNumber__c;
						existingCartDeliveryGroups[0].Shipping_Condition__c = productMap.get(existingCartItem.Product2Id)?.Shipping_Condition__c;

						//existingCartDeliveryGroups[0].CartId = cartId;
						existingCartDeliveryGroups[0].Name = 'Delivery for ' + productMap.get(existingCartItem.Product2Id)?.Name;
						existingCartDeliveryGroups[0].DeliveryMethodId = defaultDeliveryMethod.Id;

						existingCartDeliveryGroups[0].BillingAddress__c = billingAddressId;
						existingCartDeliveryGroups[0].ShippingAddress__c = shippingAddressId;

						existingCartDeliveryGroups[0].DesiredDeliveryDate = deliveryDate;

						existingCartDeliveryGroups[0].SplitShipmentId__c = String.valueOf(existingCartDeliveryGroups[0].DesiredDeliveryDate.dayOfYear()) + '|' + splitShipmentId;
						existingCartDeliveryGroups[0].ShipmentSizeType__c = String.valueOf(detail.ProductDetail.shippingMode);
						existingCartDeliveryGroups[0].Shipment_Size__c = detail.ProductDetail.loadVolume;

						existingCartDeliveryGroups[0].PONumber__c = lineItem.PoNumber;
						existingCartDeliveryGroups[0].ShipmentTonnage__c = lineItem.Tonnage;

						defaultCartDeliveryGroupUpdated = true;
					} else {
						CartDeliveryGroup deliveryGroup = new CartDeliveryGroup();

						System.debug('----- Assigning fields to cart delivery group ----');
						System.debug('Product detail (from front-end):');
						System.debug(detail);
						System.debug('existing CartItem:');
						System.debug(existingCartItem);

						deliveryGroup.Quantity__c = 1;
						deliveryGroup.DeliveryText__c = lineItem.DeliveryText;
						deliveryGroup.ShippingInstructions = lineItem.DeliveryText;

						Date deliveryDate = Date.valueOf(lineItem.deliveryDate);

						String quoteNumber;

						for(PricebookEntry pbEntry : pricebookEntries) {
							if(pbEntry.Product2Id == existingCartItem.Product2Id) {
								Date validToDate = Date.newInstance(pbEntry.ValidTo__c.year() ,pbEntry.ValidTo__c.month(), pbEntry.ValidTo__c.day());
								Date validFromDate = Date.newInstance(pbEntry.ValidFrom__c.year() ,pbEntry.ValidFrom__c.month(), pbEntry.ValidFrom__c.day());
								if(deliverydate <= validToDate && deliveryDate >= validFromDate) {
									quoteNumber = pbEntry.Quote_Number__c;
								}
							}
						}

						//deliveryGroup.Quote_Number__c = productIdToPricebookEntry.get(existingCartItem.Product2Id)?.Quote_Number__c;
						deliveryGroup.Quote_Number__c = quoteNumber;
						deliveryGroup.AccountExternalNumber__c = effectiveAccount.AccountExternalNumber__c;

						deliveryGroup.IsHold__c = effectiveAccount.IsHold__c;
						deliveryGroup.MaterialNumber__c = productMap.get(existingCartItem.Product2Id)?.MaterialNumber__c;
						deliveryGroup.Shipping_Condition__c = productMap.get(existingCartItem.Product2Id)?.Shipping_Condition__c;

						deliveryGroup.CartId = cartId;
						deliveryGroup.Name = 'Delivery for ' + productMap.get(existingCartItem.Product2Id)?.Name;
						deliveryGroup.DeliveryMethodId = defaultDeliveryMethod.Id;

						deliveryGroup.BillingAddress__c = billingAddressId;
						deliveryGroup.ShippingAddress__c = shippingAddressId;

						deliveryGroup.DesiredDeliveryDate = deliveryDate;

						deliveryGroup.SplitShipmentId__c = String.valueOf(deliveryGroup.DesiredDeliveryDate.dayOfYear()) + '|' + splitShipmentId;
						deliveryGroup.ShipmentSizeType__c = String.valueOf(detail.ProductDetail.shippingMode);
						deliveryGroup.Shipment_Size__c = detail.ProductDetail.loadVolume;

						deliveryGroup.PONumber__c = lineItem.PoNumber;
						deliveryGroup.ShipmentTonnage__c = lineItem.Tonnage;

						List<CartDeliveryGroup> newDeliveryGroups = new List<CartDeliveryGroup>();
						if (productIdToNewDeliveryGroups.containsKey(productId)) {
							newDeliveryGroups = productIdToNewDeliveryGroups.get(productId);
						}
						newDeliveryGroups.add(deliveryGroup);
						productIdToNewDeliveryGroups.put(productId, newDeliveryGroups);
					}
				}
			}
		}

//		System.debug('----- product id to cart delivery groups map -----');
//		System.debug(productIdToNewDeliveryGroups);

		List<CartDeliveryGroup> cartDeliveryGroupsToInsert = new List<CartDeliveryGroup>();
		for (Id productId : productIdToNewDeliveryGroups.keySet()) {
			cartDeliveryGroupsToInsert.addAll(productIdToNewDeliveryGroups.get(productId));
		}

		System.debug('----- cart delivery groups to insert -----');
		System.debug(cartDeliveryGroupsToInsert);

		insert cartDeliveryGroupsToInsert;
		update existingCartDeliveryGroups;

		Set<CartDeliveryGroup> deliveryGroupsDeduplication = new Set<CartDeliveryGroup>();
		List<CartDeliveryGroup> updatedDeliveryGroupsToRemove = new List<CartDeliveryGroup>();
		deliveryGroupsDeduplication.addAll(existingCartDeliveryGroups);
		updatedDeliveryGroupsToRemove.addAll(deliveryGroupsDeduplication);
		//delete updatedDeliveryGroupsToRemove;

		List<CartItem> cartItemsToInsert = new List<CartItem>();
		for (ProductDetail detail : details) {
			CartItem existingCartItem = existingCartItemsMap.get(detail.ProductDetail.CartItemId);
			List<CartDeliveryGroup> deliveryGroups = productIdToNewDeliveryGroups.get(existingCartItem.Product2Id);

			for (CartDeliveryGroup deliveryGroup : deliveryGroups) {
				CartItem newCartItem = new CartItem();
//				System.debug('---- creating cart items ----');
//				System.debug('existing cart item:');
//				System.debug(existingCartItem);
//				System.debug('linked to delivery group:');
//				System.debug(deliveryGroup);

				newCartItem.Name = productMap.get(existingCartItem.Product2Id).Name;
				newCartItem.Sku = productMap.get(existingCartItem.Product2Id).StockKeepingUnit;

				newCartItem.Product2Id = existingCartItem.Product2Id;
				newCartItem.Type = 'Product';
				newCartItem.CartId = cartId;
				//                newCartItem.CurrencyIsoCode = 'USD';

				newCartItem.CartDeliveryGroupId = deliveryGroup.Id;

				newCartItem.Quantity = deliveryGroup.Quantity__c;
				newCartItem.TotalListPrice = 0;
				newCartItem.UnitAdjustmentAmount = 0;
				newCartItem.TotalLineAmount = existingCartItem.SalesPrice;
				newCartItem.TotalPrice = existingCartItem.SalesPrice;
				newCartItem.SalesPrice = existingCartItem.SalesPrice;
				newCartItem.UnitAdjustedPrice = existingCartItem.SalesPrice;

				cartItemsToInsert.add(newCartItem);
			}
		}

		System.debug('------ cart items to insert -------');
		System.debug(cartItemsToInsert);

		insert cartItemsToInsert;

		Set<CartItem> cartItemsDeduplication = new Set<CartItem>();
		List<CartItem> updatedItemsToRemove = new List<CartItem>();
		cartItemsDeduplication.addAll(existingCartItemsMap.values());
		updatedItemsToRemove.addAll(cartItemsDeduplication);
//		delete updatedItemsToRemove;
	}

	public class ProductDetail {
		List<SplitShipmentLineItem> listOfLineItem { get; set; }
		public Details ProductDetail { get; set; }
	}

	public class Details {
		public String CartItemId { get; set; }
		public Datetime startDate { get; set; }
		public Datetime endDate { get; set; }
		public String unitOfMeasure { get; set; }
		public Decimal shippingMode { get; set; }
		public Decimal loadVolume { get; set; }
		public Decimal quantity { get; set; }
		public String poNumber { get; set; }
		public String DeliveryText { get; set; }
	}

	public class SplitShipmentLineItem {
		public String CartItemId { get; set; }
		public String deliveryDate { get; set; }
		public Decimal Quantity { get; set; }
		public Decimal Tonnage { get; set; }
		public String DeliveryText { get; set; }
		public String PoNumber { get; set; }
	}

	public class SplitShipmentDefaults {
		public String defaultPoNumber { get; set; }
		public String defaultDeliveryText { get; set; }
		public Decimal defaultLoadVolume { get; set; }
		public String defaultShipmentType { get; set; }
	}

	// old

	public class shipmentData {
		public List<shipmentDataLine> shipmentDataLine;
	}

	public class shipmentDataLine {
		public String index;
		public String PurchaseOrder;
		public String RequestedDate;
		public String CartItemId;
		public String Quantity;
		public String DeliveryInstructions;
	}
}
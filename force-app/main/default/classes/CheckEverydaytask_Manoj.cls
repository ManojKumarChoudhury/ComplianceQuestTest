public class CheckEverydaytask_Manoj implements Queueable {
    public void execute(QueueableContext context) {
        List<compliancequest__SQX_Part__c> parts = [SELECT Id, Name, compliancequest__Active__c, compliancequest__Part_Number__c, compliancequest_SQX_Product__c FROM compliancequest__SQX_Part__c WHERE compliancequest__Active__c = true];
        List<Product2> productsToInsert = new List<Product2>();
        Map<String, Product2> existingProducts = new Map<String, Product2>();
        for(Product2 product : [SELECT Id, Name, ProductCode, IsActive FROM Product2 WHERE IsActive = true]){
            existingProducts.put(product.ProductCode, product);
        }
        for(compliancequest__SQX_Part__c part : parts){
            if(part.compliancequest_SQX_Product__c == null){
                if(existingProducts.containsKey(part.compliancequest__Part_Number__c)){
                    part.compliancequest_SQX_Product__c = existingProducts.get(part.compliancequest__Part_Number__c).Id;
                } else {
                    Product2 newProduct = new Product2();
                    newProduct.Name = part.Name;
                    newProduct.ProductCode = part.compliancequest__Part_Number__c;
                    newProduct.IsActive = true;
                    productsToInsert.add(newProduct);
                }
            }
        }
        if(!productsToInsert.isEmpty()){
            insert productsToInsert;
        }
        update parts;
    }
}
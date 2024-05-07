public class CheckEverydaytask_Manoj implements Queueable {
    public void execute(QueueableContext context) {
        List<compliancequest__SQX_Part__c> partList = [Select Id, compliancequest_SQX_Product__c, compliancequest__Active__c 
                                                       From compliancequest__SQX_Part__c];
        List<Product2> proList = [Select Id, (Select Id, compliancequest__Active__c ,compliancequest_SQX_Product__c 
                                              From compliancequest__SQX_Parts__r) From Product2];
        List<Product2> newProductList = new List<Product2>();
        for (compliancequest__SQX_Part__c pr: partList){
            if(pr.compliancequest__Active__c == True && pr.compliancequest_SQX_Product__c == Null){
                Product2 pro = new Product2();
                pro.Name = pr.Name;
                pro.ProductCode = pr.compliancequest__Part_Number__c;
                pro.IsActive = True;
                newProductList.add(pro);
            }
        }
        if(!newProductList.isEmpty()){
            insert newProductList;
        }
        for(Product2 prd: proList){
            for(compliancequest__SQX_Part__c part : prd.compliancequest__SQX_Parts__r){
                if(prd.ProductCode == part.compliancequest__Part_Number__c){
                    part.compliancequest_SQX_Product__c = prd.Id;
                }
            }
        }
        update proList;
    }
}
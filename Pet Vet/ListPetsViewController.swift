//
//  ListPetsViewController.swift
//  Pet Vet
//
//  Created by Christopher Burgess on 11/11/15.
//  Copyright © 2015 Christopher Burgess. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class ListPetsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
     
     @IBOutlet var petTableView: UITableView!
     
     var storedPets = [Pet]()      // local array of fetched pets
     var deletePetIndexPath: NSIndexPath? = nil
     
     let StoredPetKey = "Stored Pet Count"
     
     override func viewDidLoad() {
          super.viewDidLoad()
          self.petTableView.delegate = self
          
          do {
               try fetchedResultsController.performFetch()
          } catch _ {
          }

          fetchedResultsController.delegate = self
          
          self.tableView.tableFooterView = UIView()
     }

     override func viewWillAppear(animated: Bool) {
          super.viewWillAppear(animated)
          self.storedPets = self.fetchAllPets()
          
          // Save the pet count using NSUserDefaults
          NSUserDefaults.standardUserDefaults().setInteger(storedPets.count, forKey: StoredPetKey)
          
          print("storedPets.count: \(storedPets.count)")    // DEBUG
          
          petTableView.backgroundColor = UIColor(patternImage: UIImage(named:"pawBackgroundLight")!)
     }
     
     override func viewDidAppear(animated: Bool) {
          super.viewDidAppear(animated)
          
          dispatch_async(dispatch_get_main_queue(), { () -> Void in
               self.petTableView.reloadData()
          })
     }
     
     override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          let sectionData = self.fetchedResultsController.sections![section]
          return sectionData.numberOfObjects
     }
     
     override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
          
          let cell = tableView.dequeueReusableCellWithIdentifier("petCell", forIndexPath: indexPath) as! PetTableViewCell
          
          let pet = fetchedResultsController.objectAtIndexPath(indexPath)

          let petSex = pet.valueForKey("sex")!
          let petBreed = pet.valueForKey("breed")!
          let petSpecies = pet.valueForKey("species")!
          let detailText = "\(petSex) \(petBreed)"
          
          cell.petNameLabel.text = pet.name
          cell.sexAndBreedLabel.text = detailText
          
          let agePet = pet as! Pet
          let age = agePet.calculateAge()
          cell.ageLabel.text = age

          if petSex as! String == "Male" {
               if petSpecies as! String == "Dog" {
                    cell.pawPrintImageView.image = UIImage(named: "dogBlue")
               } else {
                    cell.pawPrintImageView.image = UIImage(named: "catBlue")
               }
          } else {
               if petSpecies as! String == "Dog" {
                    cell.pawPrintImageView.image = UIImage(named: "dogPink")
               } else {
                    cell.pawPrintImageView.image = UIImage(named: "catPink")
               }
          }
          return cell
     }
     
     // ***********************
     // * Swipe to delete Pet *
     // ***********************
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
          if editingStyle == .Delete {
               deletePetIndexPath = indexPath
               let petToDelete = fetchedResultsController.objectAtIndexPath(indexPath)
               confirmDelete(petToDelete.name)
          }
     }
     
     // **************************
     // * Selected a Pet to View *
     // **************************
     override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
          
          let controller = storyboard!.instantiateViewControllerWithIdentifier("MenuViewController") as! MenuViewController
          
          let pet = fetchedResultsController.objectAtIndexPath(indexPath)
          
          controller.selectedPet = pet as! Pet
          
          self.navigationController!.pushViewController(controller, animated: true)
     }
     
     
     func controllerWillChangeContent(controller: NSFetchedResultsController) {
          self.petTableView.reloadData()
     }
     
     // ******************************************
     // * Lazy fetchedResultsController property *
     // ******************************************
     lazy var fetchedResultsController: NSFetchedResultsController = {
          let fetchRequest = NSFetchRequest(entityName: "Pet")
          
          fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
          
          let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
          
          return fetchedResultsController
     } ()
     
     // **************************
     // * Fetches all saved Pets *
     // **************************
     func fetchAllPets() -> [Pet] {
          let error: NSErrorPointer = nil
          let fetchRequest = NSFetchRequest(entityName: "Pet")
          let results: [AnyObject]?
          do {
               results = try self.sharedContext.executeFetchRequest(fetchRequest)
          } catch let error1 as NSError {
               error.memory = error1
               results = nil
          }
          
          if error != nil {
               print("fetchAllPets() error: \(error)")
          }
          
          return results as! [Pet]
     }
     
     
     // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
     var sharedContext: NSManagedObjectContext {
          return CoreDataStackManager.sharedInstance().managedObjectContext!
     }
     

     func confirmDelete (pet: String) {
          let alert = UIAlertController(title: "Delete Pet", message: "Are you sure you want to remove \(pet)?", preferredStyle: .ActionSheet)
          
          let DeleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: handleDeletePet)
          let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: cancelDeletePet)
          alert.addAction(DeleteAction)
          alert.addAction(CancelAction)
          
          self.presentViewController(alert, animated: true, completion: nil)
     }
     
     
     func handleDeletePet(alertAction: UIAlertAction!) -> Void {
          if let indexPath = deletePetIndexPath {
               tableView.beginUpdates()
               
               let petToDelete = fetchedResultsController.objectAtIndexPath(indexPath)
               as! NSManagedObject
               
               sharedContext.deleteObject(petToDelete)
               CoreDataStackManager.sharedInstance().saveContext()
               
               tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
               
               deletePetIndexPath = nil
               tableView.endUpdates()
          }
          
          // Update Pet Count in NSUserDefaults
          NSUserDefaults.standardUserDefaults().setInteger(storedPets.count-1, forKey: StoredPetKey)
     }
     
     func cancelDeletePet(alertAction: UIAlertAction!) {
          deletePetIndexPath = nil
     }
     
     
}


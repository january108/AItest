//
//  ViewController.swift
//  AItest
//
//  Created by reiko on 2018/03/28.
//  Copyright © 2018年 myname. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var myText: UITextView!
    
    var imagePicker: UIImagePickerController!
    
    @IBAction func btnCamera(_ sender: Any) {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func btnPicture(_ sender: Any) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        myText.text = ""
    }
    
    // カメラロールが完了したら、呼び出される
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // カメラロールを閉じる
        imagePicker.dismiss(animated: true, completion: nil)
        
        // 選択した画像が存在するか
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else{
            return
        }
        
        myText.text = ""
        
        // イメージビューを表示する
        myImage.image = image
        
        // 画像を予測する
        predict(inputImage: image)
        
    }
    
    // 画像を予測する
    func predict(inputImage: UIImage){
        // 機械学習のモデルを作成する
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else{
            return
        }
        
        // モデルのリクエストを作成し、予測結果が返ってきたら表示する
        let request = VNCoreMLRequest(model: model){
            request, error in
            guard let results = request.results as? [VNClassificationObservation] else{
                return
            }
            
            // バックグラウンド処理
            DispatchQueue.main.async {
                for result in results{
                    // 確率が１％以上のものをテキストビューに表示する
                    let per = Int(result.confidence * 100)
                    if per >= 1{
                        let name = result.identifier
                        self.myText.text.append("これは、\(name)です。（確率：\(per)%）")
                    }
                }
            }
        }

        // 画像を学習モデルに渡せる形式に変換する
        guard let ciImage = CIImage(image: inputImage) else{
            return
        }
        let imageHandler = VNImageRequestHandler(ciImage: ciImage)
        
        // バックグラウンド実行
        DispatchQueue.global(qos: .userInteractive).async {

            do{
                // 画像予測を実行する
                try imageHandler.perform([request])
            }catch{
                print("エラー \(error)")
            }
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


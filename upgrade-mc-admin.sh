#!/bin/bash

echo "Installing Mission Control Admin API..."

cd /opt/mission-control

npm install body-parser

cat > admin-api.js << 'ADMIN'
import express from "express"
import { exec } from "child_process"

const app = express()
app.use(express.json())

function run(cmd){
 return new Promise((resolve,reject)=>{
  exec(cmd,(err,stdout,stderr)=>{
   if(err){reject(stderr)}
   else{resolve(stdout)}
  })
 })
}

app.post("/admin/run", async (req,res)=>{

 const cmd=req.body.cmd

 if(!cmd){
  res.status(400).json({error:"missing cmd"})
  return
 }

 try{

  const output=await run(cmd)

  res.json({
   success:true,
   output:output
  })

 }catch(err){

  res.json({
   success:false,
   error:err
  })

 }

})

app.listen(4001,()=>{
 console.log("Admin API running on 4001")
})
ADMIN


pm2 start admin-api.js --name mc-admin

pm2 save

echo "Admin API installed"

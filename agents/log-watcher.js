import fs from "fs"
import pg from "pg"

const { Pool } = pg

const pool = new Pool({
 connectionString: process.env.DATABASE_URL,
 ssl:{rejectUnauthorized:false}
})

const logFile="/root/.pm2/logs/server-error.log"

let size=0

setInterval(async ()=>{

 try{

  const stats=fs.statSync(logFile)

  if(stats.size>size){

   const stream=fs.createReadStream(logFile,{
    start:size,
    end:stats.size
   })

   stream.on("data",async chunk=>{

    const text=chunk.toString()

    if(text.includes("Error")){
     await pool.query(
      "INSERT INTO events(type,message) VALUES($1,$2)",
      ["error","Server error detected"]
     )
    }

   })

   size=stats.size

  }

 }catch(err){}

},5000)

console.log("Log watcher running")

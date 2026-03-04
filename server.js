process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

import express from "express"
import pg from "pg"
import cors from "cors"
import path from "path"
import { fileURLToPath } from "url"
import http from "http"
import { Server } from "socket.io"
import si from "systeminformation"

const { Pool } = pg

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const app = express()
const server = http.createServer(app)
const io = new Server(server)

app.use(cors())
app.use(express.json())

const pool = new Pool({
 connectionString: process.env.DATABASE_URL,
 ssl: {
  rejectUnauthorized: false
 }
})

app.use("/mc", express.static(path.join(__dirname,"mc")))

app.get("/api/projects", async(req,res)=>{
 const r = await pool.query("SELECT * FROM projects ORDER BY id")
 res.json(r.rows)
})

app.get("/api/events", async(req,res)=>{
 const r = await pool.query("SELECT * FROM events ORDER BY timestamp DESC LIMIT 20")
 res.json(r.rows)
})

setInterval(async()=>{

 const cpu = await si.currentLoad()
 const mem = await si.mem()
 const disk = await si.fsSize()

 io.emit("telemetry",{
  cpu: cpu.currentLoad,
  memUsed:(mem.active/1024/1024/1024).toFixed(2),
  memTotal:(mem.total/1024/1024/1024).toFixed(2),
  disk: disk[0].use
 })

},3000)

const port = process.env.PORT || 3000

server.listen(port,()=>{
 console.log("Mission Control running on",port)
})

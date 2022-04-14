// ==> Import libraries <==
import { readFile } from 'fs/promises';
import mongoose from 'mongoose';
import express from 'express';
import bodyParser from 'body-parser';

// ==> Get settings properties <==
const env = JSON.parse(await readFile('./settings.json'));

// ==> Import/get player model <==
import { data } from './models/playerModel.js'
const playerModel = mongoose.model('Player')

const app = express();
app.use(bodyParser.urlencoded({
	extended: true
}));
app.use(bodyParser.json());

mongoose.connect(`mongodb+srv://${env.MONGO_USER}:${env.MONGO_PASS}@cluster1.b5bfb.mongodb.net/myFirstDatabase?retryWrites=true&w=majority`, { useNewUrlParser: true, useUnifiedTopology: true });
var db = mongoose.connection;

app.use((req, res, next) => {
	const b64auth = (req.headers.authorization || '').split(' ')[1] || '';
	const [login, password] = Buffer.from(b64auth, 'base64').toString().split(':');

	if (login && password && login === env.AUTH.login && password === env.AUTH.password) {
		return next();
	}

	res.set('WWW-Authenticate', 'Basic realm="401"');
	res.status(401).send('Authentication required.');
});

app.get("/player-data/:id", async (request, response) => {
	async function playerDataCheck() {
		const playerData = await playerModel.findOne({
			userID: `${request.params.id}`
		});

		if (playerData) {
			return playerData;
		} else {
			const newPlayerDataInstance = new playerModel({
				userID: `${request.params.id}`,
				fartCoins: 0
			})

			const newPlayerData = await newPlayerDataInstance.save()
			return newPlayerData
		}
	}

	response.json(await playerDataCheck());
});

app.post('/player-data/update-fartCoins/:id', async (request, response) => {
	await playerModel.findOneAndUpdate(
		{ userID: `${request.params.id}` },
		{ $set: { fartCoins: request.body.fartCoins } }
	);

	response.send("Updated Database.");
})

db.on('error', console.error.bind(console, 'connection error:'));

db.once('open', function () {
	console.log('Connection To MongoDB Atlas Successful!');
});

const listener = app.listen(env.PORT, () => {
	console.log('Your app is listening on port ' + listener.address().port);
});
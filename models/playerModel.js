import mongoose from 'mongoose';

const Schema = mongoose.Schema;
const schema = new Schema({
	userID: String,
	fartCoins: Number
});

const Player = mongoose.model('Player', schema);

export var data = { player: Player, schema: schema };
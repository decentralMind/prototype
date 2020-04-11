//51 percent simple consensus algorithm model.
// BigNumber implmentation for bettery precision.

const BigNumber = require('bignumber.js');

function BN(value) {
    return new BigNumber(value);
}

const CONSENSUS = BN('51');
const HUND = BN('100');

function calPer(incBy, from, to) {
    incBy = BN(incBy);
    for (let i = from; i < to; i++) {

        const totalComm = BN(i);

        // Get the amount of vote needed.
        // totalComm * (CONSENSUS/100);

        const requireVote = CONSENSUS.div(HUND).times(totalComm);

        let addInc;

        if (totalComm.modulo(HUND).eq(BN('0'))) {
            addInc = requireVote;
        } else {
            addInc = requireVote.plus(incBy);
        }

        // What percent is increased by adding 1 voter.
        // (100 / requireVote) * addInc;
        const perInc = HUND.div(requireVote).times(addInc);

        console.log('Total community: ', totalComm.toString());
        console.log('Require vote: ', requireVote.toString());
        console.log('Increase by one: ', addInc.toString());
        console.log('Percentage increase: ', perInc.toString());

        // Get the difference in percentage.
        const incDiff = perInc.minus(HUND);
        console.log('Increase Difference Per: ', incDiff.toString());

        // Reduce the voter by 1.
        const reduceByOne = requireVote.minus(BN('1'));
        console.log('Total Community reduced by one: ', reduceByOne.toString());

        const reductionPer = HUND.div(requireVote).times(reduceByOne);
        console.log('reduction percentage', reductionPer.toString());

        const decDiff = HUND.minus(reductionPer);
        console.log('decrease percentage difference', decDiff.toString());

        console.log('-------------------------------------');
    }
}

calPer(1, 1, 500) ;

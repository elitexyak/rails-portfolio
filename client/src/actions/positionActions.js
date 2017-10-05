import fetch from 'isomorphic-fetch';

export function fetchPositions(portfolio_id) {
  return function(dispatch) {
    dispatch({type: 'LOADING_POSITIONS'})
    return fetch('/api/portfolios/' + portfolio_id)
    .then(res => {return res.json()})
    .then(responseJson => {
      dispatch({type: 'FETCH_POSITIONS', payload: responseJson});
      fetchLastClosePrices(dispatch, responseJson.open_positions);
    });
  }
}

// .then(Client.checkStatus)
// .then(Client.parseJSON)

export function fetchLastClosePrices(dispatch, open_positions) {
  let symbols = open_positions.map( function(open_position) {return open_position.stock_symbol.name});
  fetch('/api/daily_trades/last_close?symbols=' + symbols.toString())
  .then(res => {return res.json()})
  .then(responseJson => {dispatch( {type: 'FETCH_LAST_CLOSE_PRICES', payload: responseJson} )});
}

export function addPosition(open_position) {
  return function(dispatch) {
    dispatch({type: 'ADDING_POSITION'})
    return fetch('/api/open_positions/', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        portfolio_id: open_position.portfolio_id,
        stock_symbol_id: open_position.stock_symbol_id,
        quantity: open_position.quantity,
        cost: open_position.cost,
        date_acquired: open_position.date_acquired,
      })
    })
    .then(res => {return res.json()})
    .then(responseJson => {
      dispatch({type: 'ADD_POSITION', payload: responseJson});
    });
  }
}

export function deletePosition(index) {
  return function(dispatch) {
    dispatch({type: 'REMOVING_POSITION'})
    dispatch({type: 'DELETE_POSITION', payload: index});
  }
}
